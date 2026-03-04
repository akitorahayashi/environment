//! Shared config deployment from ansible roles to local config root.
//!
//! Replicates Python `_deploy_configs_for_roles`: before ansible execution,
//! ensures each role's config directory is deployed to `~/.config/menv/roles/`.

use std::collections::HashSet;
use std::path::Path;

use crate::domain::error::AppError;
use crate::domain::ports::role_catalog::RoleCatalog;
use crate::domain::ports::tag_catalog::TagCatalog;

/// Deploy configs for roles associated with the given tags.
///
/// For each tag, resolves the owning role. If that role has a config directory
/// in the ansible assets, copies it to `local_config_root/{role}` (skip if exists).
pub fn deploy_for_tags(
    tags: &[String],
    ansible_dir: &Path,
    local_config_root: &Path,
    tag_catalog: &dyn TagCatalog,
    role_catalog: &dyn RoleCatalog,
) -> Result<(), AppError> {
    let available: HashSet<String> = role_catalog.roles_with_config()?.into_iter().collect();

    let mut deployed = HashSet::new();
    for tag in tags {
        let Some(role) = tag_catalog.role_for_tag(tag) else {
            continue;
        };
        if !available.contains(&role) || !deployed.insert(role.clone()) {
            continue;
        }

        let target = local_config_root.join(&role);
        if target.exists() {
            continue;
        }

        let source = ansible_dir.join("roles").join(&role).join("config");
        if let Err(e) = copy_dir_recursive(&source, &target) {
            let _ = std::fs::remove_dir_all(&target);
            return Err(e);
        }
        println!("  Deployed config for {role}");
    }

    Ok(())
}

/// Recursively copy a directory tree.
pub fn copy_dir_recursive(src: &Path, dst: &Path) -> Result<(), AppError> {
    if !src.is_dir() {
        return Err(AppError::Config(format!(
            "config source directory is missing: {}",
            src.display()
        )));
    }
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
