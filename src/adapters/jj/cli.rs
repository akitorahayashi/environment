//! Jujutsu (jj) configuration adapter — sets global jj identity via `jj config set --user`.

use std::path::{Path, PathBuf};
use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::jj::JjPort;

#[derive(Default)]
pub struct JjCli {
    pub home_dir: Option<PathBuf>,
    pub bin_path: Option<PathBuf>,
}

impl JjCli {
    fn command(&self) -> Command {
        let mut cmd = Command::new(self.bin_path.as_deref().unwrap_or(Path::new("jj")));
        if let Some(home) = &self.home_dir {
            cmd.env("HOME", home);
            cmd.env("USERPROFILE", home);
        }
        cmd
    }

    fn run_config(&self, key: &str, value: &str) -> Result<(), AppError> {
        let output = self
            .command()
            .args(["config", "set", "--user", key, value])
            .output()
            .map_err(|e| AppError::Config(format!("failed to run jj config: {e}")))?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            return Err(AppError::Config(format!("jj config set {key} failed: {stderr}")));
        }
        Ok(())
    }

    fn read_config(&self, key: &str) -> String {
        self.command()
            .args(["config", "get", key])
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default()
    }
}

impl JjPort for JjCli {
    fn set_identity(&self, name: &str, email: &str) -> Result<(), AppError> {
        self.run_config("user.name", name)?;
        self.run_config("user.email", email)?;
        Ok(())
    }

    fn get_identity(&self) -> Result<(String, String), AppError> {
        let name = self.read_config("user.name");
        let email = self.read_config("user.email");
        Ok((name, email))
    }

    fn is_available(&self) -> bool {
        which::which(self.bin_path.as_deref().unwrap_or(Path::new("jj"))).is_ok()
    }
}
