//! Ansible port — interface for playbook execution, tag resolution, and role discovery.

use std::collections::HashMap;

use crate::domain::error::AppError;

/// Unified interface for Ansible playbook execution and catalog queries.
pub trait AnsiblePort {
    /// Run playbook with the given profile and tag selection.
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError>;

    /// List roles that have a config directory.
    fn roles_with_config(&self) -> Result<Vec<String>, AppError>;

    /// Get all available tags.
    fn all_tags(&self) -> Vec<String>;

    /// Get mapping of role names to their associated tags.
    fn tags_by_role(&self) -> &HashMap<String, Vec<String>>;

    /// Get the role name for a given tag.
    fn role_for_tag(&self, tag: &str) -> Option<&str>;

    /// Validate that all provided tags exist in the catalog.
    fn validate_tags(&self, tags: &[String]) -> bool;
}
