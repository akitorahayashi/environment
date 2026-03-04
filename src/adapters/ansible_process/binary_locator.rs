//! Ansible binary path resolution.

use std::path::PathBuf;

use crate::domain::error::AppError;

/// Locate the ansible-playbook binary.
pub fn locate_ansible_playbook() -> Result<PathBuf, AppError> {
    which::which("ansible-playbook").map_err(|e| AppError::AnsibleExecution {
        message: format!("ansible-playbook not found in PATH: {e}"),
        exit_code: None,
    })
}
