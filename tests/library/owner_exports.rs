//! Verify public API surfaces remain accessible.

use std::collections::HashMap;

#[test]
fn provisioning_tag_resolution_is_public() {
    let mut groups = HashMap::new();
    groups.insert("rust".to_string(), vec!["rust-platform".to_string(), "rust-tools".to_string()]);
    let tags = mev::provisioning::tag_selection::resolve_tags("rust", &groups);
    assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
}

#[test]
fn identity_resolves_identities() {
    use mev::identity::model::IdentityScope;
    let identity = mev::identity::model::resolve_identity_scope("p");
    assert_eq!(identity, Some(IdentityScope::Personal));
}
