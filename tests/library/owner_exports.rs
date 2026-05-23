//! Verify public API surfaces remain accessible.

use std::collections::{HashMap, HashSet};

#[test]
fn provisioning_tag_resolution_is_public() {
    let mut composite_tags = HashMap::new();
    composite_tags
        .insert("rust".to_string(), vec!["rust-platform".to_string(), "rust-tools".to_string()]);

    let atomic_tags: HashSet<String> =
        ["rust-platform", "rust-tools", "shell"].into_iter().map(String::from).collect();

    let units = mev::provisioning::tag_selection::normalize_requested_tags(
        &["rust".to_string(), "shell".to_string()],
        &composite_tags,
        &atomic_tags,
    )
    .unwrap();

    assert_eq!(units.len(), 2);
    assert_eq!(units[0].name, "rust");
    assert_eq!(units[1].name, "shell");
}

#[test]
fn identity_resolves_identities() {
    use mev::identity::model::IdentityScope;
    let identity = mev::identity::model::resolve_identity_scope("p");
    assert_eq!(identity, Some(IdentityScope::Personal));
}
