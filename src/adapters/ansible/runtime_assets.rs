//! Runtime materialization for embedded ansible assets.

use std::path::Path;

use rust_embed::RustEmbed;
use tempfile::TempDir;

use crate::domain::error::AppError;

#[derive(RustEmbed)]
#[folder = "src/assets/ansible/"]
struct EmbeddedAnsibleAssets;

/// Materialize embedded ansible assets into a process-scoped temporary directory.
pub fn materialize_embedded_ansible_dir() -> Result<TempDir, AppError> {
    let temp_dir = tempfile::Builder::new()
        .prefix("mev-ansible-")
        .tempdir()
        .map_err(|e| AppError::Config(format!("failed to create ansible temp directory: {e}")))?;

    for relative in EmbeddedAnsibleAssets::iter() {
        let relative_path = relative.as_ref();
        let Some(content) = EmbeddedAnsibleAssets::get(relative_path) else {
            return Err(AppError::Config(format!(
                "embedded ansible asset missing at runtime: {relative_path}"
            )));
        };

        let destination = temp_dir.path().join(relative_path);
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

    if !is_valid_ansible_dir(temp_dir.path()) {
        return Err(AppError::Config(format!(
            "embedded ansible assets are invalid: {}",
            temp_dir.path().display()
        )));
    }

    Ok(temp_dir)
}

pub fn is_valid_ansible_dir(dir: &Path) -> bool {
    dir.join("playbook.yml").exists() && dir.join("roles").is_dir()
}
