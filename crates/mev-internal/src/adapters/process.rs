//! Process execution adapter.

use crate::domain::DomainError;
use std::process::{Command, Output};

pub fn run_status(mut command: Command, description: &str) -> Result<(), DomainError> {
    let status = command
        .status()
        .map_err(|source| DomainError::CommandExecution(description.to_string(), source))?;
    if status.success() {
        return Ok(());
    }

    Err(DomainError::ProcessFailed(format!(
        "{description} exited with code {}",
        status.code().unwrap_or(1)
    )))
}

pub fn run_output(mut command: Command, description: &str) -> Result<Output, DomainError> {
    let output = command
        .output()
        .map_err(|source| DomainError::CommandExecution(description.to_string(), source))?;
    if output.status.success() {
        return Ok(output);
    }

    let stderr = String::from_utf8_lossy(&output.stderr);
    Err(DomainError::ProcessFailed(format!("{description} failed: {}", stderr.trim())))
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

    #[test]
    fn run_status_returns_command_execution_error_when_command_is_missing() {
        let command = Command::new("definitely-not-a-real-binary-for-mev");
        let error = run_status(command, "missing command").expect_err("expected error");

        match error {
            crate::domain::DomainError::CommandExecution(description, source) => {
                assert_eq!(description, "missing command");
                assert_eq!(source.kind(), std::io::ErrorKind::NotFound);
            }
            other => panic!("expected CommandExecution, got {other:?}"),
        }
    }

    #[test]
    fn run_output_returns_command_execution_error_when_command_is_missing() {
        let command = Command::new("definitely-not-a-real-binary-for-mev");
        let error = run_output(command, "missing command").expect_err("expected error");

        match error {
            crate::domain::DomainError::CommandExecution(description, source) => {
                assert_eq!(description, "missing command");
                assert_eq!(source.kind(), std::io::ErrorKind::NotFound);
            }
            other => panic!("expected CommandExecution, got {other:?}"),
        }
    }
}
