//! Tag catalog port — resolves available tags from authoritative sources.

/// Provides tag discovery from playbook or catalog files.
pub trait TagCatalog {
    /// Get all available tags.
    fn all_tags(&self) -> Vec<String>;

    /// Get mapping of role names to their associated tags.
    fn tags_by_role(&self) -> std::collections::HashMap<String, Vec<String>>;

    /// Get the role name for a given tag.
    fn role_for_tag(&self, tag: &str) -> Option<String>;

    /// Validate that all provided tags exist in the catalog.
    fn validate_tags(&self, tags: &[String]) -> bool;
}
