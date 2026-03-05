//! Verify public API surfaces remain accessible.

#[test]
fn domain_tag_resolution_is_public() {
    let tags = mev::domain::tag::resolve_tags("rust");
    assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
}

#[test]
fn vcs_identity_resolves_identities() {
    use mev::domain::vcs_identity::SwitchIdentity;
    let identity = mev::domain::vcs_identity::resolve_switch_identity("p");
    assert_eq!(identity, Some(SwitchIdentity::Personal));
}
