//! Version source adapter contracts.

use mev::domain::ports::version_source::VersionSource;

#[test]
fn install_script_version_source_returns_current_version() {
    let source = mev::adapters::version_source::install_script::InstallScriptVersionSource;
    let concrete_version = source.current_version().unwrap();
    assert_eq!(concrete_version, env!("CARGO_PKG_VERSION"));

    let source_ref: &dyn VersionSource = &source;
    let trait_version = source_ref.current_version().unwrap();
    assert_eq!(trait_version, env!("CARGO_PKG_VERSION"));
}
