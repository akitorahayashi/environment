use crate::error::AppError;

/// Extra variables supported by provisioning playbook execution.
#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct PlaybookVars {
    pub brew_tap_tokens: Vec<String>,
    pub brew_formula_tokens: Vec<String>,
    pub brew_cask_tokens: Vec<String>,
}

impl PlaybookVars {
    pub fn brew_formulae(taps: Vec<String>, formulae: Vec<String>) -> Self {
        Self { brew_tap_tokens: taps, brew_formula_tokens: formulae, brew_cask_tokens: Vec::new() }
    }

    pub fn brew_casks(tokens: Vec<String>) -> Self {
        Self {
            brew_tap_tokens: Vec::new(),
            brew_formula_tokens: Vec::new(),
            brew_cask_tokens: tokens,
        }
    }

    pub fn is_empty(&self) -> bool {
        self.brew_tap_tokens.is_empty()
            && self.brew_formula_tokens.is_empty()
            && self.brew_cask_tokens.is_empty()
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
