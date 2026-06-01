use crate::error::AppError;

/// Extra variables supported by provisioning playbook execution.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PlaybookVars {
    pub brew_cask_tokens: Vec<String>,
}

impl PlaybookVars {
    pub fn brew_casks(tokens: Vec<String>) -> Self {
        Self { brew_cask_tokens: tokens }
    }

    pub fn is_empty(&self) -> bool {
        self.brew_cask_tokens.is_empty()
    }
}

/// Playbook execution contract for provisioning flows.
pub trait ProvisioningRunner {
    /// Run the provisioning playbook for a profile with a tag set.
    fn run_playbook(
        &self,
        profile: &str,
        tags: &[String],
        vars: &PlaybookVars,
        verbose: bool,
    ) -> Result<(), AppError>;
}
