//! Ansible playbook execution through process invocation.

use std::path::Path;
use std::process::{Command, Stdio};

use crate::domain::error::AppError;
use crate::domain::ports::ansible_executor::AnsibleExecutor;

pub struct AnsibleProcessExecutor {
    ansible_dir: std::path::PathBuf,
    local_config_root: std::path::PathBuf,
}

impl AnsibleProcessExecutor {
    pub fn new(ansible_dir: std::path::PathBuf, local_config_root: std::path::PathBuf) -> Self {
        Self { ansible_dir, local_config_root }
    }
}

impl AnsibleExecutor for AnsibleProcessExecutor {
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError> {
        let playbook_path = self.ansible_dir.join("playbook.yml");
        let config_path = self.ansible_dir.join("ansible.cfg");

        if !playbook_path.exists() {
            return Err(AppError::AnsibleExecution {
                message: format!("playbook not found: {}", playbook_path.display()),
                exit_code: None,
            });
        }

        if !config_path.exists() {
            return Err(AppError::AnsibleExecution {
                message: format!("ansible.cfg not found: {}", config_path.display()),
                exit_code: None,
            });
        }

        let mut cmd = Command::new("uv");
        cmd.arg("run")
            .arg("ansible-playbook")
            .arg(&playbook_path)
            .arg("-e")
            .arg(format!("profile={profile}"))
            .arg("-e")
            .arg(format!("config_dir_abs_path={}", self.ansible_dir.display()))
            .arg("-e")
            .arg(format!(
                "repo_root_path={}",
                self.ansible_dir.parent().unwrap_or(Path::new(".")).display()
            ))
            .arg("-e")
            .arg(format!("local_config_root={}", self.local_config_root.display()));

        if !tags.is_empty() {
            cmd.arg("--tags").arg(tags.join(","));
        }

        if verbose {
            cmd.arg("-vvv");
        }

        cmd.env("ANSIBLE_CONFIG", &config_path);
        cmd.stdout(Stdio::inherit());
        cmd.stderr(Stdio::inherit());

        let status = cmd.status().map_err(|e| AppError::AnsibleExecution {
            message: format!("failed to run ansible-playbook: {e}"),
            exit_code: None,
        })?;

        if !status.success() {
            let code = status.code();
            return Err(AppError::AnsibleExecution {
                message: format!("ansible-playbook exited with code {}", code.unwrap_or(-1)),
                exit_code: code,
            });
        }

        Ok(())
    }
}
