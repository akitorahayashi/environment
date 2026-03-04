//! Verify public API surfaces remain accessible.

#[test]
fn domain_profile_types_are_public() {
    // Confirms that profile resolution is accessible from the library crate.
    let resolved = mev::domain::profile::resolve_profile("macbook");
    assert_eq!(resolved, Some("macbook"));
}

#[test]
fn domain_tag_resolution_is_public() {
    let tags = mev::domain::tag::resolve_tags("rust");
    assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
}

#[test]
fn domain_config_resolution_is_public() {
    let resolved = mev::domain::config::resolve_switch_profile("p");
    assert_eq!(resolved, Some("personal"));
}
