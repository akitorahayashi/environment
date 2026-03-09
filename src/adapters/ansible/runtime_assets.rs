//! Runtime materialization for embedded ansible assets.

use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use rust_embed::RustEmbed;

use crate::domain::error::AppError;

#[derive(RustEmbed)]
#[folder = "src/assets/ansible/"]
struct EmbeddedAnsibleAssets;

/// Materialize embedded ansible assets into a deterministic cache path.
pub fn materialize_embedded_ansible_dir() -> Result<PathBuf, AppError> {
    let cache_root = dirs::cache_dir()
        .ok_or_else(|| AppError::Config("unable to resolve cache directory".to_string()))?;

    let target = cache_root.join("mev").join("ansible").join(env!("CARGO_PKG_VERSION"));
    if is_valid_ansible_dir(&target) {
        return Ok(target);
    }

    let timestamp = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_err(|e| AppError::Config(format!("failed to read system clock: {e}")))?
        .as_millis();
    let staging = cache_root
        .join("mev")
        .join("ansible")
        .join(format!(".staging-{}-{timestamp}", std::process::id()));

    if staging.exists() {
        std::fs::remove_dir_all(&staging).map_err(|e| {
            AppError::Config(format!(
                "failed to clean ansible staging directory '{}': {e}",
                staging.display()
            ))
        })?;
    }

    std::fs::create_dir_all(&staging).map_err(|e| {
        AppError::Config(format!(
            "failed to create ansible staging directory '{}': {e}",
            staging.display()
        ))
    })?;

    for relative in EmbeddedAnsibleAssets::iter() {
        let relative_path = relative.as_ref();
        let Some(content) = EmbeddedAnsibleAssets::get(relative_path) else {
            if let Err(cleanup_err) = std::fs::remove_dir_all(&staging) {
                return Err(AppError::Config(format!(
                    "embedded ansible asset missing at runtime: {relative_path}; failed to clean staging '{}': {cleanup_err}",
                    staging.display()
                )));
            }
            return Err(AppError::Config(format!(
                "embedded ansible asset missing at runtime: {relative_path}"
            )));
        };

        let destination = staging.join(relative_path);
        if let Some(parent) = destination.parent() {
            std::fs::create_dir_all(parent).map_err(|e| {
                AppError::Config(format!(
                    "failed to create ansible asset parent directory '{}': {e}",
                    parent.display()
                ))
            })?;
        }
        std::fs::write(&destination, content.data.as_ref()).map_err(|e| {
            AppError::Config(format!(
                "failed to write ansible asset '{}': {e}",
                destination.display()
            ))
        })?;
    }

    if target.exists() {
        std::fs::remove_dir_all(&target).map_err(|e| {
            AppError::Config(format!(
                "failed to replace existing ansible cache '{}': {e}",
                target.display()
            ))
        })?;
    } else if let Some(parent) = target.parent() {
        std::fs::create_dir_all(parent).map_err(|e| {
            AppError::Config(format!(
                "failed to create ansible cache parent '{}': {e}",
                parent.display()
            ))
        })?;
    }

    std::fs::rename(&staging, &target).map_err(|e| {
        AppError::Config(format!(
            "failed to activate embedded ansible cache '{}' -> '{}': {e}",
            staging.display(),
            target.display()
        ))
    })?;

    if !is_valid_ansible_dir(&target) {
        return Err(AppError::Config(format!(
            "embedded ansible cache is invalid: {}",
            target.display()
        )));
    }

    Ok(target)
}

pub fn is_valid_ansible_dir(dir: &Path) -> bool {
    dir.join("playbook.yml").exists() && dir.join("roles").is_dir()
}
