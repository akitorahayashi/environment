use std::cell::RefCell;
use std::collections::HashMap;
use std::path::PathBuf;

use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;

pub struct FakeAnsiblePort {
    pub roles_with_config: Vec<String>,
    pub tag_to_role: HashMap<String, String>,
    pub roles_config_dir: HashMap<String, PathBuf>,
    pub all_tags: Vec<String>,
    pub tags_by_role: HashMap<String, Vec<String>>,
    pub events: RefCell<Vec<String>>,
}

impl FakeAnsiblePort {
    pub fn new() -> Self {
        Self {
            roles_with_config: Vec::new(),
            tag_to_role: HashMap::new(),
            roles_config_dir: HashMap::new(),
            all_tags: Vec::new(),
            tags_by_role: HashMap::new(),
            events: RefCell::new(Vec::new()),
        }
    }
}

impl AnsiblePort for FakeAnsiblePort {
    fn run_playbook(&self, profile: &str, tags: &[String], _verbose: bool) -> Result<(), AppError> {
        self.events.borrow_mut().push(format!("run_playbook: {} with tags {:?}", profile, tags));
        Ok(())
    }

    fn roles_with_config(&self) -> Result<Vec<String>, AppError> {
        Ok(self.roles_with_config.clone())
    }

    fn all_tags(&self) -> Vec<String> {
        self.all_tags.clone()
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

    fn role_config_dir(&self, role: &str) -> Option<PathBuf> {
        self.roles_config_dir.get(role).cloned()
    }
}
