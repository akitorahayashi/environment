//! Packaging layout contract tests.
//!
//! Validates that the project structure required for the packaged
//! distribution (pyproject.toml + bundled binaries) is present and
//! consistent.

use std::path::Path;

/// Locate the project root from CARGO_MANIFEST_DIR.
fn project_root() -> &'static Path {
    Path::new(env!("CARGO_MANIFEST_DIR"))
}

#[test]
fn pyproject_toml_exists() {
    assert!(project_root().join("pyproject.toml").exists());
}

#[test]
fn python_bootstrap_launcher_exists() {
    let launcher = project_root().join("dist").join("mev").join("launcher.py");
    assert!(launcher.exists(), "mev bootstrap launcher missing: {}", launcher.display());
}

#[test]
fn bundled_binaries_directory_exists() {
    let dir = project_root().join("dist").join("mev").join("bin");
    assert!(dir.is_dir(), "bundled_binaries directory missing: {}", dir.display());
}

#[test]
fn ansible_assets_playbook_exists() {
    let playbook = project_root().join("dist").join("mev").join("ansible").join("playbook.yml");
    assert!(playbook.exists(), "playbook.yml missing: {}", playbook.display());
}

#[test]
fn ansible_assets_roles_directory_exists() {
    let roles = project_root().join("dist").join("mev").join("ansible").join("roles");
    assert!(roles.is_dir(), "ansible roles directory missing: {}", roles.display());
}

#[test]
fn cargo_binary_name_is_mev() {
    let name = env!("CARGO_PKG_NAME");
    assert_eq!(name, "mev", "binary package name must be mev");
}
