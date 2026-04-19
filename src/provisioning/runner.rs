use crate::error::AppError;

/// Playbook execution contract for provisioning flows.
pub trait ProvisioningRunner {
    /// Run the provisioning playbook for a profile with a tag set.
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError>;
}
