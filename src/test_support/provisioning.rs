use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;

use crate::error::AppError;
use crate::provisioning::catalog::ProvisioningCatalog;
use crate::provisioning::role_configs::RoleConfigLocator;
use crate::provisioning::runner::ProvisioningRunner;

pub struct FakeProvisioningPort {
    pub roles_with_config: Vec<String>,
    pub tag_to_role: HashMap<String, String>,
    pub roles_config_dir: HashMap<String, PathBuf>,
    pub all_tags: Vec<String>,
    pub tags_by_role: HashMap<String, Vec<String>>,
    pub tag_groups: HashMap<String, Vec<String>>,
    pub full_setup_tags: Vec<String>,
    pub cask_requirements: HashMap<String, Vec<String>>,
    pub formula_requirements: HashMap<String, Vec<String>>,
    pub tap_requirements: HashMap<String, Vec<String>>,
    pub events: RefCell<Vec<String>>,
}

impl FakeProvisioningPort {
    pub fn new() -> Self {
        Self {
            roles_with_config: Vec::new(),
            tag_to_role: HashMap::new(),
            roles_config_dir: HashMap::new(),
            all_tags: Vec::new(),
            tags_by_role: HashMap::new(),
            tag_groups: HashMap::new(),
            full_setup_tags: Vec::new(),
            cask_requirements: HashMap::new(),
            formula_requirements: HashMap::new(),
            tap_requirements: HashMap::new(),
            events: RefCell::new(Vec::new()),
        }
    }
}

impl ProvisioningRunner for FakeProvisioningPort {
    fn run_playbook(
        &self,
        profile: &str,
        tags: &[String],
        vars: &crate::provisioning::runner::PlaybookVars,
        _verbose: bool,
    ) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!(
            "run_playbook: {} with tags {:?}, taps {:?}, formulae {:?}, and casks {:?}",
            profile, tags, vars.brew_tap_tokens, vars.brew_formula_tokens, vars.brew_cask_tokens
        ));
        Ok(())
    }
}

impl ProvisioningCatalog for FakeProvisioningPort {
    fn all_tags(&self) -> Vec<String> {
        self.all_tags.clone()
    }

    fn tag_groups(&self) -> &HashMap<String, Vec<String>> {
        &self.tag_groups
    }

    fn full_setup_tags(&self) -> &[String] {
        &self.full_setup_tags
    }

    fn cask_requirements(&self) -> &HashMap<String, Vec<String>> {
        &self.cask_requirements
    }

    fn formula_requirements(&self) -> &HashMap<String, Vec<String>> {
        &self.formula_requirements
    }

    fn tap_requirements(&self) -> &HashMap<String, Vec<String>> {
        &self.tap_requirements
    }

    fn tags_by_role(&self) -> &HashMap<String, Vec<String>> {
        &self.tags_by_role
    }

    fn role_for_tag(&self, tag: &str) -> Option<&str> {
        self.tag_to_role.get(tag).map(|s| s.as_str())
    }

    fn validate_tags(&self, tags: &[String]) -> bool {
        tags.iter().all(|t| self.all_tags.contains(t))
    }
}

impl RoleConfigLocator for FakeProvisioningPort {
    fn roles_with_config(&self) -> Result<Vec<String>, AppError> {
        Ok(self.roles_with_config.clone())
    }

    fn role_config_dir(&self, role: &str) -> Option<PathBuf> {
        self.roles_config_dir.get(role).cloned()
    }
}
