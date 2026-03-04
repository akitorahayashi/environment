//! Adapter contract tests for VCS configurators.
//!
//! Validates the `VcsConfigurator` trait semantics without mutating
//! actual global git/jj configuration.

use mev::domain::ports::vcs_configurator::VcsConfigurator;

#[test]
fn git_configurator_reports_available() {
    let git = mev::adapters::vcs::git_configurator::GitConfigurator;
    // git is expected to be available in the development environment.
    assert!(git.is_available());
}

#[test]
fn git_configurator_tool_name() {
    let git = mev::adapters::vcs::git_configurator::GitConfigurator;
    assert_eq!(git.tool_name(), "git");
}

#[test]
fn jj_configurator_tool_name() {
    let jj = mev::adapters::vcs::jj_configurator::JjConfigurator;
    assert_eq!(jj.tool_name(), "jj");
}

#[test]
fn git_configurator_get_identity_returns_strings() {
    let git = mev::adapters::vcs::git_configurator::GitConfigurator;
    let result = git.get_identity();
    // Should return Ok with string pair (may be empty if no global config).
    assert!(result.is_ok());
    let (name, email) = result.unwrap();
    // Values are strings (possibly empty); just verify no panic.
    let _ = (name.len(), email.len());
}
