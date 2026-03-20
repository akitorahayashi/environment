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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn run_status_returns_ok_on_success() {
        let command = Command::new("true");
        let result = run_status(command, "true command");
        assert!(result.is_ok());
    }

    #[test]
    fn run_status_returns_error_with_code_on_failure() {
        let command = Command::new("false");
        let result = run_status(command, "false command");
        let error = result.expect_err("expected error");
        assert_eq!(error.to_string(), "false command exited with code 1");
    }

    #[test]
    fn run_output_returns_output_on_success() {
        let mut command = Command::new("echo");
        command.arg("hello world");
        let result = run_output(command, "echo command");
        let output = result.expect("expected output");
        assert_eq!(String::from_utf8_lossy(&output.stdout).trim(), "hello world");
    }

    #[test]
    fn run_output_returns_error_with_stderr_on_failure() {
        let mut command = Command::new("sh");
        command.args(["-c", "echo 'some error' >&2 && false"]);
        let result = run_output(command, "failing script");
        let error = result.expect_err("expected error");
        assert_eq!(error.to_string(), "failing script failed: some error");
    }
}
