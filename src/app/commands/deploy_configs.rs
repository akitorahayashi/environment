//! Shared config deployment from ansible roles to local config root.
//!
//! Replicates Python `_deploy_configs_for_roles`: before ansible execution,
//! ensures each role's config directory is deployed to `~/.config/mev/roles/`.

use std::collections::HashSet;
use std::path::Path;

use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::ports::fs::FsPort;

/// Deploy configs for roles associated with the given tags.
///
/// For each tag, resolves the owning role. If that role has a config directory
/// in the ansible assets, copies it to `local_config_root/{role}`.
/// When `overwrite` is false, existing config directories are skipped.
/// When `overwrite` is true, existing config directories are replaced.
pub fn deploy_for_tags(
    tags: &[String],
    fs: &dyn FsPort,
    local_config_root: &Path,
    ansible: &dyn AnsiblePort,
    overwrite: bool,
) -> Result<(), AppError> {
    let available: HashSet<String> = ansible.roles_with_config()?.into_iter().collect();

    let mut deployed = HashSet::new();
    for tag in tags {
        let Some(role) = ansible.role_for_tag(tag) else {
            return Err(AppError::InvalidTag(tag.to_string()));
        };
        if !available.contains(role) || !deployed.insert(role.to_string()) {
            continue;
        }

        let target = local_config_root.join(role);
        if fs.exists(&target) && !overwrite {
            continue;
        }

        if fs.exists(&target) {
            fs.remove_dir_all(&target).map_err(|e| {
                AppError::Config(format!("failed to remove existing config for {role}: {e}"))
            })?;
        }

        let Some(source) = ansible.role_config_dir(role) else {
            continue;
        };

        if let Err(e) = copy_dir_recursive(&source, &target, fs) {
            let _ = fs.remove_dir_all(&target);
            return Err(e);
        }
        println!("  Deployed config for {role}");
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
    use crate::testing::ansible::FakeAnsiblePort;
    use crate::testing::fs::FakeFsPort;
    use std::path::PathBuf;

    #[test]
    fn test_deploy_for_tags_success() {
        let fs = FakeFsPort::new();
        let mut ansible = FakeAnsiblePort::new();

        ansible.roles_with_config = vec!["zsh".to_string()];
        ansible.tag_to_role.insert("shell".to_string(), "zsh".to_string());
        ansible
            .roles_config_dir
            .insert("zsh".to_string(), PathBuf::from("/ansible/roles/zsh/config"));

        fs.add_dir(Path::new("/ansible/roles/zsh/config"));
        fs.add_file(Path::new("/ansible/roles/zsh/config/.zshrc"), "zsh config");

        let tags = vec!["shell".to_string()];
        let local_config_root = PathBuf::from("/local/config");

        let result = deploy_for_tags(&tags, &fs, &local_config_root, &ansible, false);
        assert!(result.is_ok());

        // Target path is /local/config/zsh
        assert!(fs.exists(Path::new("/local/config/zsh/.zshrc")));
    }
}
