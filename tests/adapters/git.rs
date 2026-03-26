//! Adapter contract tests for Git CLI.

use std::fs;

use mev::domain::ports::git::GitPort;

#[test]
fn git_cli_reports_available() {
    let git = mev::adapters::git::cli::GitCli::default();
    assert!(git.is_available());
}

#[test]
fn git_cli_get_identity_returns_strings() {
    let temp_dir = tempfile::tempdir().unwrap();

    // Create a mock .gitconfig in the temp home directory
    let gitconfig_path = temp_dir.path().join(".gitconfig");
    fs::write(gitconfig_path, "[user]\n\tname = Test User\n\temail = test@example.com\n").unwrap();

    let git = mev::adapters::git::cli::GitCli { home_dir: Some(temp_dir.path().to_path_buf()) };

    let result = git.get_identity();
    assert!(result.is_ok());
    let (name, email) = result.unwrap();
    assert_eq!(name, "Test User");
    assert_eq!(email, "test@example.com");
}

#[test]
fn git_cli_set_identity_updates_config() {
    let temp_dir = tempfile::tempdir().unwrap();

    let git = mev::adapters::git::cli::GitCli { home_dir: Some(temp_dir.path().to_path_buf()) };

    let result = git.set_identity("New User", "new@example.com");
    assert!(result.is_ok());

    let get_result = git.get_identity();
    assert!(get_result.is_ok());
    let (name, email) = get_result.unwrap();
    assert_eq!(name, "New User");
    assert_eq!(email, "new@example.com");
}
