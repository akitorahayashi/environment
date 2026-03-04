//! Adapter contract tests for Git CLI.

use mev::domain::ports::git::GitPort;

#[test]
fn git_cli_reports_available() {
    let git = mev::adapters::git::cli::GitCli;
    assert!(git.is_available());
}

#[test]
fn git_cli_get_identity_returns_strings() {
    let git = mev::adapters::git::cli::GitCli;
    let result = git.get_identity();
    assert!(result.is_ok());
    let (name, email) = result.unwrap();
    let _ = (name.len(), email.len());
}
