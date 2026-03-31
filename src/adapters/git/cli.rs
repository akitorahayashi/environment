//! Git configuration adapter — sets global git identity via `git config --global`.

use std::path::{Path, PathBuf};
use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::git::GitPort;

#[derive(Default)]
pub struct GitCli {
    pub home_dir: Option<PathBuf>,
    pub bin_path: Option<PathBuf>,
}

impl GitCli {
    fn command(&self) -> Command {
        let mut cmd = Command::new(self.bin_path.as_deref().unwrap_or(Path::new("git")));
        if let Some(home) = &self.home_dir {
            cmd.env("HOME", home);
            cmd.env("USERPROFILE", home); // for windows compat if needed, safe to set
        }
        cmd
    }

    fn run_config(&self, key: &str, value: &str) -> Result<(), AppError> {
        let output = self
            .command()
            .args(["config", "--global", key, value])
            .output()
            .map_err(|e| AppError::Config(format!("failed to run git config: {e}")))?;
        if !output.status.success() {
            let stderr = String::from_utf8_lossy(&output.stderr).trim().to_string();
            return Err(AppError::Config(format!("git config --global {key} failed: {stderr}")));
        }
        Ok(())
    }

    fn read_config(&self, key: &str) -> String {
        self.command()
            .args(["config", "--global", key])
            .output()
            .ok()
            .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
            .unwrap_or_default()
    }
}

impl GitPort for GitCli {
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
        which::which(self.bin_path.as_deref().unwrap_or(Path::new("git"))).is_ok()
    }
}
