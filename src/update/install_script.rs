//! Version source adapter.

use std::io::Write;
use std::process::Command;
use std::process::Stdio;

use crate::error::AppError;
use crate::update::version_source::VersionSource;

const EMBEDDED_INSTALL_SCRIPT: &str = include_str!("../../install.sh");

pub struct InstallScriptVersionSource;

impl VersionSource for InstallScriptVersionSource {
    fn current_version(&self) -> Result<String, AppError> {
        Ok(env!("CARGO_PKG_VERSION").to_string())
    }

    fn run_upgrade(&self) -> Result<(), AppError> {
        println!("Upgrading {} via install script...", env!("CARGO_PKG_NAME"));

        let path = std::env::var_os("PATH").unwrap_or_default();

        let mut child = Command::new("/bin/bash")
            .arg("-s")
            .env("PATH", path)
            .stdin(Stdio::piped())
            .spawn()
            .map_err(|e| {
                if e.kind() == std::io::ErrorKind::NotFound {
                    AppError::Update("bash not found. Please ensure bash is installed.".to_string())
                } else {
                    AppError::Update(format!("failed to run embedded install script: {e}"))
                }
            })?;

        if let Some(stdin) = child.stdin.as_mut() {
            stdin.write_all(EMBEDDED_INSTALL_SCRIPT.as_bytes()).map_err(|e| {
                AppError::Update(format!("failed to stream embedded install script: {e}"))
            })?;
        }

        let status = child.wait().map_err(|e| {
            if e.kind() == std::io::ErrorKind::NotFound {
                AppError::Update("bash not found. Please ensure bash is installed.".to_string())
            } else {
                AppError::Update(format!("failed to run embedded install script: {e}"))
            }
        })?;

        if !status.success() {
            return Err(AppError::Update(format!(
                "embedded install script failed with exit code {}",
                status.code().unwrap_or(-1)
            )));
        }

        Ok(())
    }
}
