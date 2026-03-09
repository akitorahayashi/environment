//! Packaging layout contract tests.
//!
//! Validates that the project structure required for the packaged
//! distribution (embedded assets + release installer) is present and
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
fn install_script_exists() {
    let script = project_root().join("install.sh");
    assert!(script.exists(), "install.sh missing: {}", script.display());
}

#[test]
fn release_workflow_exists() {
    let workflow = project_root().join(".github").join("workflows").join("release.yml");
    assert!(workflow.exists(), "release workflow missing: {}", workflow.display());
}

#[test]
fn ansible_assets_playbook_exists() {
    let playbook = project_root().join("src").join("assets").join("ansible").join("playbook.yml");
    assert!(playbook.exists(), "playbook.yml missing: {}", playbook.display());
}

#[test]
fn ansible_assets_roles_directory_exists() {
    let roles = project_root().join("src").join("assets").join("ansible").join("roles");
    assert!(roles.is_dir(), "ansible roles directory missing: {}", roles.display());
}

#[test]
fn cargo_binary_name_is_mev() {
    let name = env!("CARGO_PKG_NAME");
    assert_eq!(name, "mev", "binary package name must be mev");
}
