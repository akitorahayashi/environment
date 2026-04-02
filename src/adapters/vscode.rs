//! VSCode adapter.

use crate::domain::error::AppError;
use crate::domain::ports::vscode::VscodePort;

/// Candidate commands for VSCode CLI.
const CANDIDATE_COMMANDS: &[&str] = &[
    "code",
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
    "code-insiders",
];

pub struct VscodeCli;

impl VscodePort for VscodeCli {
    fn list_extensions(&self) -> Result<Vec<String>, AppError> {
        let command = detect_command()?;

        let output =
            std::process::Command::new(&command).arg("--list-extensions").output().map_err(
                |e| AppError::Backup(format!("failed to run '{command} --list-extensions': {e}")),
            )?;

        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr);
            return Err(AppError::Backup(format!(
                "failed to list VSCode extensions: {}",
                stderr.trim()
            )));
        }

        let stdout = String::from_utf8_lossy(&output.stdout);
        Ok(stdout.lines().map(|l| l.trim().to_string()).filter(|l| !l.is_empty()).collect())
    }
}

fn detect_command() -> Result<String, AppError> {
    for candidate in CANDIDATE_COMMANDS {
        if std::path::Path::new(candidate).is_absolute() && std::path::Path::new(candidate).exists()
        {
            return Ok(candidate.to_string());
        }
        if which::which(candidate).is_ok() {
            return Ok(candidate.to_string());
        }
    }
    Err(AppError::Backup(
        "VSCode command (code or code-insiders) not found in PATH or default locations".to_string(),
    ))
}
