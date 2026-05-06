//! Antigravity adapter.

use crate::backup::antigravity_port::AntigravityPort;
use crate::error::AppError;

/// Candidate commands for Antigravity CLI.
const CANDIDATE_COMMANDS: &[&str] =
    &["antigravity", "/Applications/Antigravity.app/Contents/Resources/app/bin/antigravity"];

pub struct AntigravityCli;

impl AntigravityPort for AntigravityCli {
    fn list_extensions(&self) -> Result<Vec<String>, AppError> {
        let command = detect_command()?;
        let output =
            std::process::Command::new(&command).arg("--list-extensions").output().map_err(
                |e| AppError::Backup(format!("failed to run '{command} --list-extensions': {e}")),
            )?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(AppError::Backup(format!(
                "failed to list Antigravity extensions: {}",
                stderr.trim()
            )));
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout
            .lines()
            .map(str::trim)
            .filter(|line| !line.is_empty() && !line.starts_with("[createInstance]"))
            .map(str::to_string)
            .collect())
    }
}

fn detect_command() -> Result<String, AppError> {
    for candidate in CANDIDATE_COMMANDS {
        if let Ok(path) = which::which(candidate) {
            return Ok(path.to_string_lossy().into_owned());
        }
    }
    Err(AppError::Backup("Antigravity command not found in PATH or default locations".to_string()))
}
