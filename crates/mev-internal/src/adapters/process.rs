//! Process execution adapter.

use std::process::{Command, Output};

pub fn run_status(
    mut command: Command,
    description: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let status = command.status()?;
    if status.success() {
        return Ok(());
    }

    Err(format!("{description} exited with code {}", status.code().unwrap_or(1)).into())
}

pub fn run_output(
    mut command: Command,
    description: &str,
) -> Result<Output, Box<dyn std::error::Error>> {
    let output = command.output()?;
    if output.status.success() {
        return Ok(output);
    }

    let stderr = String::from_utf8_lossy(&output.stderr);
    Err(format!("{description} failed: {}", stderr.trim()).into())
}
