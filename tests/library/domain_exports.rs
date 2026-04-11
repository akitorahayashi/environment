//! Verify public API surfaces remain accessible.

use std::collections::HashMap;

#[test]
fn domain_tag_resolution_is_public() {
    let mut groups = HashMap::new();
    groups.insert("rust".to_string(), vec!["rust-platform".to_string(), "rust-tools".to_string()]);
    let tags = mev::domain::tag::resolve_tags("rust", &groups);
    assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
}

#[test]
fn identity_resolves_identities() {
    use mev::domain::identity::IdentityScope;
    let identity = mev::domain::identity::resolve_identity_scope("p");
    assert_eq!(identity, Some(IdentityScope::Personal));
}
