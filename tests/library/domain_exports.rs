//! Verify public API surfaces remain accessible.

#[test]
fn domain_tag_resolution_is_public() {
    let tags = mev::domain::tag::resolve_tags("rust");
    assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
}

#[test]
fn identity_resolves_identities() {
    use mev::domain::identity::IdentityScope;
    let identity = mev::domain::identity::resolve_identity_scope("p");
    assert_eq!(identity, Some(IdentityScope::Personal));
}
