//! Locate ansible assets (playbook, roles) in development and packaged runtimes.

use std::path::PathBuf;

use crate::domain::error::AppError;

/// Resolve the ansible directory containing playbook.yml and roles/.
///
/// In development mode, this is `src/menv/ansible/` relative to the repository root.
/// In packaged mode, this uses a bundled or installed path.
pub fn locate_ansible_dir() -> Result<PathBuf, AppError> {
    // Development mode: resolve from current executable or known path
    let exe = std::env::current_exe().map_err(AppError::Io)?;

    // Walk up from the executable to find the repo root with src/menv/ansible/
    let mut candidate = exe.parent().map(|p| p.to_path_buf());
    for _ in 0..5 {
        if let Some(ref dir) = candidate {
            let ansible_dir = dir.join("src").join("menv").join("ansible");
            if ansible_dir.join("playbook.yml").exists() && ansible_dir.join("roles").is_dir() {
                return Ok(ansible_dir);
            }
            candidate = dir.parent().map(|p| p.to_path_buf());
        }
    }

    // Fallback: check CARGO_MANIFEST_DIR (available during cargo run)
    if let Ok(manifest_dir) = std::env::var("CARGO_MANIFEST_DIR") {
        let ansible_dir = PathBuf::from(manifest_dir).join("src").join("menv").join("ansible");
        if ansible_dir.join("playbook.yml").exists() && ansible_dir.join("roles").is_dir() {
            return Ok(ansible_dir);
        }
    }

    Err(AppError::AnsibleExecution {
        message: "ansible asset directory not found".to_string(),
        exit_code: None,
    })
}
