//! Adapter contract tests for Jujutsu CLI.

use std::fs;
#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use mev::domain::ports::jj::JjPort;

#[cfg(windows)]
fn write_fake_jj(dir: &Path) -> PathBuf {
    let script_name = "jj.bat";
    let path = dir.join(script_name);

    let fake_config = dir.join(".fake_jj_config");

    let bat_content = format!(
        r#"@echo off
set FAKE_CONFIG={config_path}

if "%1"=="config" (
    if "%2"=="set" if "%3"=="--user" (
        for %%K in (user.name user.email) do (
            if "%4"=="%%K" (
                echo %%K=%~5 >> "%FAKE_CONFIG%"
                exit /b 0
            )
        )
    )
    if "%2"=="get" (
        for %%K in (user.name user.email) do (
            if "%3"=="%%K" (
                for /F "tokens=2 delims==" %%A in ('findstr /C:"%%K=" "%FAKE_CONFIG%" 2^>nul') do echo %%A
                exit /b 0
            )
        )
    )
)
exit /b 0
"#,
        config_path = fake_config.display()
    );
    fs::write(&path, bat_content).unwrap();

    path
}

#[cfg(unix)]
fn write_fake_jj(dir: &Path) -> PathBuf {
    let script_name = "jj";
    let path = dir.join(script_name);

    let fake_config = dir.join(".fake_jj_config");

    let sh_content = format!(
        r#"#!/bin/sh
FAKE_CONFIG="{config_path}"
touch "$FAKE_CONFIG"

if [ "$1" = "config" ]; then
    if [ "$2" = "set" ] && [ "$3" = "--user" ]; then
        key="$4"
        value="$5"
        if [ "$key" = "user.name" ] || [ "$key" = "user.email" ]; then
            echo "$key=$value" >> "$FAKE_CONFIG"
            exit 0
        fi
    elif [ "$2" = "get" ]; then
        key="$3"
        if [ "$key" = "user.name" ] || [ "$key" = "user.email" ]; then
            grep "^$key=" "$FAKE_CONFIG" | tail -n 1 | cut -d '=' -f 2-
            exit 0
        fi
    fi
fi
exit 0
"#,
        config_path = fake_config.display()
    );
    fs::write(&path, sh_content).unwrap();
    let mut perms = fs::metadata(&path).unwrap().permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&path, perms).unwrap();

    path
}

#[test]
fn jj_cli_is_available_returns_bool() {
    let temp_dir = tempfile::tempdir().unwrap();
    let fake_jj = write_fake_jj(temp_dir.path());
    let jj = mev::adapters::jj::cli::JjCli { home_dir: None, bin_path: Some(fake_jj) };
    assert!(jj.is_available());
}

#[test]
fn jj_cli_get_identity_returns_configured_values() {
    let temp_dir = tempfile::tempdir().unwrap();
    let fake_jj = write_fake_jj(temp_dir.path());

    // Write fake config
    let fake_config = temp_dir.path().join(".fake_jj_config");
    fs::write(&fake_config, "user.name=Jj Test User\nuser.email=jj@example.com\n").unwrap();

    let jj = mev::adapters::jj::cli::JjCli {
        home_dir: Some(temp_dir.path().to_path_buf()),
        bin_path: Some(fake_jj),
    };

    let result = jj.get_identity();
    assert!(result.is_ok());
    let (name, email) = result.unwrap();
    assert_eq!(name, "Jj Test User");
    assert_eq!(email, "jj@example.com");
}

#[test]
fn jj_cli_set_identity_updates_config() {
    let temp_dir = tempfile::tempdir().unwrap();
    let fake_jj = write_fake_jj(temp_dir.path());

    let jj = mev::adapters::jj::cli::JjCli {
        home_dir: Some(temp_dir.path().to_path_buf()),
        bin_path: Some(fake_jj),
    };

    let result = jj.set_identity("New Jj User", "newjj@example.com");
    assert!(result.is_ok());

    let get_result = jj.get_identity();
    assert!(get_result.is_ok());
    let (name, email) = get_result.unwrap();
    assert_eq!(name, "New Jj User");
    assert_eq!(email, "newjj@example.com");
}
