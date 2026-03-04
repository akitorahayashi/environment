//! Locate ansible assets (playbook, roles) in development and packaged runtimes.
//!
//! Resolution order:
//! 1. `MEV_ANSIBLE_DIR` environment variable (explicit override).
//! 2. Walk up from the current executable checking both development layout
//!    (`dist/mev/ansible/`) and packaged layout (`ansible/`).
//! 3. `CARGO_MANIFEST_DIR` fallback for `cargo run` development workflows.
//!
//! On failure, the error includes all searched candidate paths for diagnosis.

use std::path::PathBuf;

use crate::domain::error::AppError;

/// Resolve the ansible directory containing `playbook.yml` and `roles/`.
pub fn locate_ansible_dir() -> Result<PathBuf, AppError> {
    let mut searched: Vec<PathBuf> = Vec::new();

    // 1. Explicit environment variable override.
    if let Ok(env_dir) = std::env::var("MEV_ANSIBLE_DIR") {
        let dir = PathBuf::from(&env_dir);
        if is_valid_ansible_dir(&dir) {
            return Ok(dir);
        }
        searched.push(dir);
    }

    // 2. Walk up from the executable.
    if let Ok(exe) = std::env::current_exe() {
        let mut candidate = exe.parent().map(|p| p.to_path_buf());
        for _ in 0..6 {
            if let Some(ref dir) = candidate {
                // Development layout: <repo>/dist/mev/ansible/
                let dev_path = dir.join("dist").join("mev").join("ansible");
                if is_valid_ansible_dir(&dev_path) {
                    return Ok(dev_path);
                }
                searched.push(dev_path);

                // Packaged layout: <site-packages>/.../mev/ansible/
                let installed_path = dir.join("ansible");
                if is_valid_ansible_dir(&installed_path) {
                    return Ok(installed_path);
                }
                searched.push(installed_path);

                candidate = dir.parent().map(|p| p.to_path_buf());
            }
        }
    }

    // 3. CARGO_MANIFEST_DIR fallback (cargo run / cargo test).
    if let Ok(manifest_dir) = std::env::var("CARGO_MANIFEST_DIR") {
        let ansible_dir = PathBuf::from(&manifest_dir).join("dist").join("mev").join("ansible");
        if is_valid_ansible_dir(&ansible_dir) {
            return Ok(ansible_dir);
        }
        searched.push(ansible_dir);
    }

    searched.dedup();

    let candidates =
        searched.iter().map(|p| format!("  {}", p.display())).collect::<Vec<_>>().join("\n");

    Err(AppError::AnsibleExecution {
        message: format!(
            "ansible asset directory not found.\n\
             Searched candidates:\n{candidates}\n\
             Set MEV_ANSIBLE_DIR to override, or ensure playbook.yml and roles/ \
             exist in one of these locations."
        ),
        exit_code: None,
    })
}

fn is_valid_ansible_dir(dir: &std::path::Path) -> bool {
    dir.join("playbook.yml").exists() && dir.join("roles").is_dir()
}
