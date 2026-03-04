//! Jujutsu (jj) configuration adapter — sets global jj identity via `jj config set --user`.

use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::jj::JjPort;

pub struct JjCli;

impl JjPort for JjCli {
    fn set_identity(&self, name: &str, email: &str) -> Result<(), AppError> {
        run_config("user.name", name)?;
        run_config("user.email", email)?;
        Ok(())
    }

    fn get_identity(&self) -> Result<(String, String), AppError> {
        let name = read_config("user.name");
        let email = read_config("user.email");
        Ok((name, email))
    }

    fn is_available(&self) -> bool {
        which::which("jj").is_ok()
    }
}

fn run_config(key: &str, value: &str) -> Result<(), AppError> {
    let output = Command::new("jj")
        .args(["config", "set", "--user", key, value])
        .output()
        .map_err(|e| AppError::Config(format!("failed to run jj config: {e}")))?;
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
        return Err(AppError::Config(format!("jj config set {key} failed: {stderr}")));
    }
    Ok(())
}

fn read_config(key: &str) -> String {
    Command::new("jj")
        .args(["config", "get", key])
        .output()
        .ok()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_default()
}
