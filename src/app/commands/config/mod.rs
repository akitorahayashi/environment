//! `config` command orchestration — deploy configuration.

use std::path::Path;

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;

/// Deploy role configs from ansible assets to local config root.
pub fn deploy(
    ctx: &DependencyContainer,
    role: Option<String>,
    overwrite: bool,
) -> Result<(), AppError> {
    let available = ctx.ansible.roles_with_config()?;

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
        let source = ctx.ansible_dir.join("roles").join(role_name).join("config");
        let target = ctx.local_config_root.join(role_name);

        if target.exists() && !overwrite {
            println!("  {role_name}: config exists (use --overwrite to replace)");
            continue;
        }
        let staging = ctx.local_config_root.join(format!(".{role_name}.staging"));
        if staging.exists() {
            std::fs::remove_dir_all(&staging).map_err(|e| {
                AppError::Config(format!("failed to clean staging for {role_name}: {e}"))
            })?;
        }
        copy_dir_recursive(&source, &staging)?;
        if target.exists() {
            std::fs::remove_dir_all(&target).map_err(|e| {
                AppError::Config(format!("failed to remove existing config for {role_name}: {e}"))
            })?;
        }
        std::fs::rename(&staging, &target).map_err(|e| {
            AppError::Config(format!("failed to activate config for {role_name}: {e}"))
        })?;
        println!("✓ {role_name}: config deployed");
    }

    Ok(())
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<(), AppError> {
    std::fs::create_dir_all(dst)?;
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        if src_path.is_dir() {
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}
