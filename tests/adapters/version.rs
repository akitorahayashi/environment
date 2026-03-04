//! Version source adapter contracts.

use mev::domain::ports::version_source::VersionSource;

#[test]
fn cargo_version_returns_current() {
    let source = mev::adapters::version_source::cargo::CargoVersion;
    let version = source.current_version().unwrap();
    assert_eq!(version, env!("CARGO_PKG_VERSION"));
}

#[test]
fn needs_update_detects_difference() {
    let source = mev::adapters::version_source::cargo::CargoVersion;
    assert!(source.needs_update("0.1.0", "0.2.0"));
    assert!(!source.needs_update("1.0.0", "1.0.0"));
    // Downgrade must not trigger update
    assert!(!source.needs_update("1.0.0", "0.9.0"));
}
