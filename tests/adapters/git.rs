//! Adapter contract tests for Git CLI.

use std::fs;
#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use mev::identity::git_config::GitPort;

#[cfg(windows)]
fn write_fake_git(dir: &Path) -> Result<PathBuf, Box<dyn std::error::Error>> {
    let script_name = "git.bat";
    let path = dir.join(script_name);

    let fake_config = dir.join(".fake_git_config");

    let bat_content = format!(
        r#"@echo off
set FAKE_CONFIG={config_path}

if "%1"=="config" if "%2"=="--global" (
    for %%K in (user.name user.email) do (
        if "%3"=="%%K" (
            if "%~4"=="" (
                :: read mode
                for /F "tokens=2 delims==" %%A in ('findstr /C:"%%K=" "%FAKE_CONFIG%" 2^>nul') do echo %%A
            ) else (
                :: write mode
                echo %%K=%~4 >> "%FAKE_CONFIG%"
            )
            exit /b 0
        )
    )
)
exit /b 0
"#,
        config_path = fake_config.display()
    );
    fs::write(&path, bat_content)?;

    Ok(path)
}

#[cfg(unix)]
fn write_fake_git(dir: &Path) -> Result<PathBuf, Box<dyn std::error::Error>> {
    let script_name = "git";
    let path = dir.join(script_name);

    let fake_config = dir.join(".fake_git_config");

    let sh_content = format!(
        r#"#!/bin/sh
FAKE_CONFIG="{config_path}"
touch "$FAKE_CONFIG"

if [ "$1" = "config" ] && [ "$2" = "--global" ]; then
    key="$3"
    value="$4"
    if [ "$key" = "user.name" ] || [ "$key" = "user.email" ]; then
        if [ -z "$value" ]; then
            # Read
            grep "^$key=" "$FAKE_CONFIG" | tail -n 1 | cut -d '=' -f 2-
        else
            # Write
            echo "$key=$value" >> "$FAKE_CONFIG"
        fi
        exit 0
    fi
fi
exit 0
"#,
        config_path = fake_config.display()
    );
    fs::write(&path, sh_content)?;
    let mut perms = fs::metadata(&path)?.permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&path, perms)?;

    Ok(path)
}

#[test]
fn git_cli_reports_available() -> Result<(), Box<dyn std::error::Error>> {
    let temp_dir = tempfile::tempdir()?;
    let fake_git = write_fake_git(temp_dir.path())?;
    let git = mev::identity::git_cli::GitCli { home_dir: None, bin_path: Some(fake_git) };
    assert!(git.is_available());
    Ok(())
}

#[test]
fn git_cli_get_identity_returns_strings() -> Result<(), Box<dyn std::error::Error>> {
    let temp_dir = tempfile::tempdir()?;
    let fake_git = write_fake_git(temp_dir.path())?;

    // Write fake config
    let fake_config = temp_dir.path().join(".fake_git_config");
    fs::write(&fake_config, "user.name=Test User\nuser.email=test@example.com\n")?;

    let git = mev::identity::git_cli::GitCli {
        home_dir: Some(temp_dir.path().to_path_buf()),
        bin_path: Some(fake_git),
    };

    let result = git.get_identity();
    assert!(result.is_ok());
    let (name, email) = result?;
    assert_eq!(name, "Test User");
    assert_eq!(email, "test@example.com");
    Ok(())
}

#[test]
fn git_cli_set_identity_updates_config() -> Result<(), Box<dyn std::error::Error>> {
    let temp_dir = tempfile::tempdir()?;
    let fake_git = write_fake_git(temp_dir.path())?;

    let git = mev::identity::git_cli::GitCli {
        home_dir: Some(temp_dir.path().to_path_buf()),
        bin_path: Some(fake_git),
    };

    let result = git.set_identity("New User", "new@example.com");
    assert!(result.is_ok());

    let get_result = git.get_identity();
    assert!(get_result.is_ok());
    let (name, email) = get_result?;
    assert_eq!(name, "New User");
    assert_eq!(email, "new@example.com");
    Ok(())
}
