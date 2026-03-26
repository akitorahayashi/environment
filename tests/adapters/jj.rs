//! Adapter contract tests for Jujutsu CLI.

use std::fs;

use mev::domain::ports::jj::JjPort;

#[test]
fn jj_cli_is_available_returns_bool() {
    let jj = mev::adapters::jj::cli::JjCli::default();
    // May be false in CI; just verify no panic.
    let _ = jj.is_available();
}

#[test]
fn jj_cli_get_identity_returns_configured_values() {
    // Only run if jj is available, to avoid failing in minimal environments.
    let jj_test = mev::adapters::jj::cli::JjCli::default();
    if !jj_test.is_available() {
        return;
    }

    let temp_dir = tempfile::tempdir().unwrap();

    // Create a mock jj config file in the temp home directory (.jjconfig.toml)
    let config_toml_path = temp_dir.path().join(".jjconfig.toml");
    fs::write(config_toml_path, "[user]\nname = \"Jj Test User\"\nemail = \"jj@example.com\"\n")
        .unwrap();

    let jj = mev::adapters::jj::cli::JjCli { home_dir: Some(temp_dir.path().to_path_buf()) };

    let result = jj.get_identity();
    assert!(result.is_ok());
    let (name, email) = result.unwrap();
    assert_eq!(name, "Jj Test User");
    assert_eq!(email, "jj@example.com");
}

#[test]
fn jj_cli_set_identity_updates_config() {
    // Only run if jj is available
    let jj_test = mev::adapters::jj::cli::JjCli::default();
    if !jj_test.is_available() {
        return;
    }

    let temp_dir = tempfile::tempdir().unwrap();

    let jj = mev::adapters::jj::cli::JjCli { home_dir: Some(temp_dir.path().to_path_buf()) };

    let result = jj.set_identity("New Jj User", "newjj@example.com");
    assert!(result.is_ok());

    let get_result = jj.get_identity();
    assert!(get_result.is_ok());
    let (name, email) = get_result.unwrap();
    assert_eq!(name, "New Jj User");
    assert_eq!(email, "newjj@example.com");
}
