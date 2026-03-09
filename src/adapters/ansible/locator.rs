//! Locate ansible assets for runtime execution.
//!
//! Resolution order:
//! 1. `MEV_ANSIBLE_DIR` environment variable (explicit override).
//! 2. Embedded ansible assets materialized at runtime.
//! 3. `CARGO_MANIFEST_DIR/src/assets/ansible` for `cargo run` workflows.

use std::path::PathBuf;

use crate::adapters::ansible::runtime_assets;
use crate::domain::error::AppError;

/// Resolve the ansible directory containing `playbook.yml` and `roles/`.
pub fn locate_ansible_dir() -> Result<PathBuf, AppError> {
    let mut searched: Vec<PathBuf> = Vec::new();

    // 1. Explicit environment variable override.
    if let Ok(env_dir) = std::env::var("MEV_ANSIBLE_DIR") {
        let dir = PathBuf::from(&env_dir);
        if runtime_assets::is_valid_ansible_dir(&dir) {
            return Ok(dir);
        }
        searched.push(dir);
    }

    // 2. Embedded runtime assets.
    let embedded_error = match runtime_assets::materialize_embedded_ansible_dir() {
        Ok(dir) => return Ok(dir),
        Err(err) => Some(err.to_string()),
    };

    // 3. CARGO_MANIFEST_DIR fallback for cargo run / cargo test.
    if let Ok(manifest_dir) = std::env::var("CARGO_MANIFEST_DIR") {
        let ansible_dir = PathBuf::from(&manifest_dir).join("src").join("assets").join("ansible");
        if runtime_assets::is_valid_ansible_dir(&ansible_dir) {
            return Ok(ansible_dir);
        }
        searched.push(ansible_dir);
    }

    searched.dedup();

    let candidates =
        searched.iter().map(|p| format!("  {}", p.display())).collect::<Vec<_>>().join("\n");
    let embedded_detail = embedded_error
        .as_ref()
        .map(|message| format!("\nEmbedded materialization error:\n  {message}"))
        .unwrap_or_default();

    Err(AppError::AnsibleExecution {
        message: format!(
            "ansible asset directory not found.\n\
             Searched candidates:\n{candidates}{embedded_detail}\n\
             Set MEV_ANSIBLE_DIR to override, or ensure playbook.yml and roles/ \
             exist in one of these locations."
        ),
        exit_code: None,
    })
}
