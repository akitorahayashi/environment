use std::collections::HashSet;
use std::path::{Path, PathBuf};

use crate::error::AppError;
use crate::host_fs::fs::FsPort;
use crate::provisioning::catalog::ProvisioningCatalog;

/// Role configuration discovery contract.
pub trait RoleConfigLocator {
    /// List roles that have a config directory.
    fn roles_with_config(&self) -> Result<Vec<String>, AppError>;

    /// Resolve config directory for a role.
    fn role_config_dir(&self, role: &str) -> Option<PathBuf>;
}

/// Deploy role configs required by the selected tags.
pub fn deploy_for_tags(
    tags: &[String],
    fs: &dyn FsPort,
    local_config_root: &Path,
    catalog: &dyn ProvisioningCatalog,
    role_config_locator: &dyn RoleConfigLocator,
    overwrite: bool,
) -> Result<(), AppError> {
    let available: HashSet<String> = role_config_locator.roles_with_config()?.into_iter().collect();

    let mut deployed = HashSet::new();
    for tag in tags {
        let Some(role) = catalog.role_for_tag(tag) else {
            return Err(AppError::InvalidTag(tag.to_string()));
        };
        if !available.contains(role) || !deployed.insert(role.to_string()) {
            continue;
        }

        let dest_dir = local_config_root.join(role);
        if fs.exists(&dest_dir) && !overwrite {
            continue;
        }

        if fs.exists(&dest_dir) {
            fs.remove_dir_all(&dest_dir).map_err(|e| {
                AppError::Config(format!("failed to remove existing config for {role}: {e}"))
            })?;
        }

        let Some(source) = role_config_locator.role_config_dir(role) else {
            continue;
        };

        if let Err(e) = copy_dir_recursive(&source, &dest_dir, fs) {
            let _ = fs.remove_dir_all(&dest_dir);
            return Err(e);
        }
        println!("  Deployed config for {role}");
    }

    Ok(())
}

/// Deploy role configs selected by the `config deploy` flow.
pub fn deploy_selected(
    fs: &dyn FsPort,
    role_config_locator: &dyn RoleConfigLocator,
    local_config_root: &Path,
    role: Option<String>,
    overwrite: bool,
) -> Result<(), AppError> {
    let available = role_config_locator.roles_with_config()?;

    let roles_to_deploy = if let Some(role_name) = role {
        if !available.contains(&role_name) {
            return Err(AppError::Config(format!(
                "role '{role_name}' has no config directory. Available: {}",
                available.join(", ")
            )));
        }
        vec![role_name]
    } else {
        if available.is_empty() {
            println!("No roles with config directories found.");
            return Ok(());
        }
        available
    };

    for role_name in &roles_to_deploy {
        let Some(source) = role_config_locator.role_config_dir(role_name) else {
            continue;
        };
        let target = local_config_root.join(role_name);

        if fs.exists(&target) && !overwrite {
            println!("  {role_name}: config exists (use --overwrite to replace)");
            continue;
        }
        let staging = local_config_root.join(format!(".{role_name}.staging"));
        if fs.exists(&staging) {
            fs.remove_dir_all(&staging).map_err(|e| {
                AppError::Config(format!("failed to clean staging for {role_name}: {e}"))
            })?;
        }
        copy_dir_recursive(&source, &staging, fs)?;
        if fs.exists(&target) {
            fs.remove_dir_all(&target).map_err(|e| {
                AppError::Config(format!("failed to remove existing config for {role_name}: {e}"))
            })?;
        }
        fs.rename(&staging, &target).map_err(|e| {
            AppError::Config(format!("failed to activate config for {role_name}: {e}"))
        })?;
        println!("✓ {role_name}: config deployed");
    }

    Ok(())
}

/// Recursively copy a directory tree.
pub fn copy_dir_recursive(src: &Path, dst: &Path, fs: &dyn FsPort) -> Result<(), AppError> {
    if !fs.is_dir(src) {
        return Err(AppError::Config(format!(
            "config source directory is missing: {}",
            src.display()
        )));
    }
    fs.create_dir_all(dst)?;
    for src_path in fs.read_dir(src)? {
        let file_name = src_path.file_name().ok_or_else(|| {
            AppError::Io(std::io::Error::new(std::io::ErrorKind::InvalidInput, "invalid file name"))
        })?;
        let dst_path = dst.join(file_name);
        if fs.is_dir(&src_path) {
            copy_dir_recursive(&src_path, &dst_path, fs)?;
        } else {
            fs.copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::provisioning::catalog::ProvisioningCatalog;
    use crate::test_support::host_fs::FakeFsPort;
    use crate::test_support::provisioning::FakeProvisioningPort;

    fn fake_catalog_with_shell() -> FakeProvisioningPort {
        let mut fake = FakeProvisioningPort::new();
        fake.roles_with_config = vec!["zsh".to_string()];
        fake.tag_to_role.insert("shell".to_string(), "zsh".to_string());
        fake.roles_config_dir.insert("zsh".to_string(), PathBuf::from("/ansible/roles/zsh/config"));
        fake
    }

    #[test]
    fn deploy_for_tags_success() {
        let fs = FakeFsPort::new();
        let fake = fake_catalog_with_shell();

        fs.add_dir(Path::new("/ansible/roles/zsh/config"));
        fs.add_file(Path::new("/ansible/roles/zsh/config/.zshrc"), "zsh config");

        let tags = vec!["shell".to_string()];
        let local_config_root = PathBuf::from("/local/config");

        let result = deploy_for_tags(&tags, &fs, &local_config_root, &fake, &fake, false);
        assert!(result.is_ok());
        assert!(fs.exists(Path::new("/local/config/zsh/.zshrc")));
    }

    #[test]
    fn deploy_selected_success() {
        let fs = FakeFsPort::new();
        let mut fake = FakeProvisioningPort::new();
        fake.roles_with_config = vec!["git".to_string()];
        fake.roles_config_dir.insert("git".to_string(), PathBuf::from("/ansible/roles/git/config"));

        fs.add_dir(Path::new("/ansible/roles/git/config"));
        fs.add_file(Path::new("/ansible/roles/git/config/.gitconfig"), "git config");

        let local_config_root = PathBuf::from("/local/config");
        let result =
            deploy_selected(&fs, &fake, &local_config_root, Some("git".to_string()), false);
        assert!(result.is_ok());
        assert!(fs.exists(Path::new("/local/config/git/.gitconfig")));
    }

    #[test]
    fn catalog_resolve_for_tag_is_used() {
        let fake = fake_catalog_with_shell();
        let tags = fake.tag_groups();
        let _ = tags;
        assert_eq!(fake.role_for_tag("shell"), Some("zsh"));
    }

    #[test]
    fn deploy_selected_rejects_unknown_role() {
        let fs = FakeFsPort::new();
        let fake = FakeProvisioningPort::new();
        let result = deploy_selected(
            &fs,
            &fake,
            Path::new("/local/config"),
            Some("unknown".to_string()),
            false,
        );
        assert!(result.is_err());
    }
}
