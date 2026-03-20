//! `config` command orchestration — deploy configuration.

use crate::app::DependencyContainer;
use crate::app::commands::deploy_configs::copy_dir_recursive;
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;
use crate::domain::ports::fs::FsPort;

/// Deploy role configs from ansible assets to local config root.
pub fn deploy(
    ctx: &DependencyContainer,
    role: Option<String>,
    overwrite: bool,
) -> Result<(), AppError> {
    deploy_internal(&ctx.fs, &ctx.ansible, &ctx.local_config_root, role, overwrite)
}

fn deploy_internal(
    fs: &dyn FsPort,
    ansible: &dyn AnsiblePort,
    local_config_root: &std::path::Path,
    role: Option<String>,
    overwrite: bool,
) -> Result<(), AppError> {
    let available = ansible.roles_with_config()?;

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
        let Some(source) = ansible.role_config_dir(role_name) else {
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::ansible::FakeAnsiblePort;
    use crate::testing::fs::FakeFsPort;
    use std::path::PathBuf;

    #[test]
    fn test_deploy_config_success() {
        let fs = FakeFsPort::new();
        let mut ansible = FakeAnsiblePort::new();

        ansible.roles_with_config = vec!["git".to_string()];
        ansible
            .roles_config_dir
            .insert("git".to_string(), PathBuf::from("/ansible/roles/git/config"));

        fs.add_dir(std::path::Path::new("/ansible/roles/git/config"));
        fs.add_file(std::path::Path::new("/ansible/roles/git/config/.gitconfig"), "git config");

        let local_config_root = PathBuf::from("/local/config");

        let result =
            deploy_internal(&fs, &ansible, &local_config_root, Some("git".to_string()), false);
        assert!(result.is_ok());

        assert!(fs.exists(std::path::Path::new("/local/config/git/.gitconfig")));
    }
}
