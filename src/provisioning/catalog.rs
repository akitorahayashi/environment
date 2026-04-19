use std::collections::HashMap;

/// Read-only provisioning catalog contract.
pub trait ProvisioningCatalog {
    /// Get all available tags.
    fn all_tags(&self) -> Vec<String>;

    /// Get all configured tag groups.
    fn tag_groups(&self) -> &HashMap<String, Vec<String>>;

    /// Get full setup tags for the create flow.
    fn full_setup_tags(&self) -> &[String];

    /// Get role-to-tag mapping.
    fn tags_by_role(&self) -> &HashMap<String, Vec<String>>;

    /// Resolve a tag to its owner role.
    fn role_for_tag(&self, tag: &str) -> Option<&str>;

    /// Validate that all tags exist in the catalog.
    fn validate_tags(&self, tags: &[String]) -> bool;
}
