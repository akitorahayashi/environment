//! Backup installed VSCode extensions to a JSON file.
//!
//! Detects the `code` command, lists installed extensions, and writes
//! the result as JSON to disk.

use std::path::Path;

use crate::domain::error::AppError;

/// Candidate commands for VSCode CLI.
const CANDIDATE_COMMANDS: &[&str] = &[
    "code",
    "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code",
    "code-insiders",
];

/// Execute VSCode extensions backup.
///
/// Detects the VSCode CLI, lists installed extensions, and writes
/// the result to `output_file` as JSON.
pub fn execute(output_file: &Path) -> Result<(), AppError> {
    let command = detect_command()?;
    let extensions = list_extensions(&command)?;
    write_backup(output_file, &extensions)?;

    println!("VSCode extensions list backed up to: {}", output_file.display());
    Ok(())
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

fn list_extensions(command: &str) -> Result<Vec<String>, AppError> {
    let output =
        std::process::Command::new(command).arg("--list-extensions").output().map_err(|e| {
            AppError::Backup(format!("failed to run '{command} --list-extensions': {e}"))
        })?;

    if !output.status.success() {
        return Err(AppError::Backup(
            "failed to list VSCode extensions. If VSCode is running, close it and try again"
                .to_string(),
        ));
    }

    let stdout = String::from_utf8_lossy(&output.stdout);
    Ok(stdout.lines().map(|l| l.trim().to_string()).filter(|l| !l.is_empty()).collect())
}

fn write_backup(output_file: &Path, extensions: &[String]) -> Result<(), AppError> {
    if let Some(parent) = output_file.parent() {
        std::fs::create_dir_all(parent)?;
    }

    let payload = serde_json::json!({ "extensions": extensions });
    let content = serde_json::to_string_pretty(&payload)
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))?;

    std::fs::write(output_file, format!("{content}\n"))?;
    Ok(())
}
