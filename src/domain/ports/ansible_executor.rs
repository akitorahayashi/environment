//! Ansible process execution port.

use crate::domain::error::AppError;

/// Executes ansible-playbook with resolved parameters.
pub trait AnsibleExecutor {
    /// Run playbook with the given profile and tag selection.
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError>;
}
