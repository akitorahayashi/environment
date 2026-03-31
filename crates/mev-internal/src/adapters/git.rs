//! Git CLI adapter.

use std::fs;
use std::process::Command;

use crate::adapters::process;

#[derive(Default)]
pub struct GitAdapter {
    pub mock_env_path: Option<String>,
    pub current_dir: Option<std::path::PathBuf>,
}

impl GitAdapter {
    pub fn delete_submodule_worktree(
        &self,
        submodule_path: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        process::run_status(
            self.git_command(["submodule", "deinit", "-f", submodule_path]),
            &format!("git submodule deinit -f {submodule_path}"),
        )?;

        process::run_status(
            self.git_command(["rm", "-f", "-r", submodule_path]),
            &format!("git rm -f -r {submodule_path}"),
        )?;

        Ok(())
    }

    pub fn remove_submodule_module_dir(
        &self,
        submodule_path: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let base_dir = match &self.current_dir {
            Some(dir) => dir.clone(),
            None => std::env::current_dir()?,
        };
        let modules_path = base_dir.join(".git").join("modules").join(submodule_path);
        if modules_path.exists() {
            fs::remove_dir_all(&modules_path)?;
        }
        Ok(())
    }

    pub fn remove_submodule_config_section(
        &self,
        submodule_path: &str,
    ) -> Result<(), Box<dyn std::error::Error>> {
        let output = process::run_output(
            self.git_command([
                "config",
                "--remove-section",
                &format!("submodule.{submodule_path}"),
            ]),
            &format!("git config --remove-section submodule.{submodule_path}"),
        );

        match output {
            Ok(_) => Ok(()),
            Err(err) if err.to_string().contains("No such section") => Ok(()),
            Err(err) => Err(err),
        }
    }

    pub fn current_origin_url(&self) -> Result<String, Box<dyn std::error::Error>> {
        let output = process::run_output(
            self.git_command(["remote", "get-url", "origin"]),
            "git remote get-url origin",
        )?;
        Ok(String::from_utf8(output.stdout)?.trim().to_owned())
    }

    fn git_command<const N: usize, S>(&self, args: [S; N]) -> Command
    where
        S: AsRef<std::ffi::OsStr>,
    {
        let mut command = Command::new("git");
        if let Some(env_path) = &self.mock_env_path {
            let original_path = std::env::var_os("PATH").unwrap_or_default();
            let mut paths = std::env::split_paths(&original_path).collect::<Vec<_>>();
            paths.insert(0, std::path::PathBuf::from(env_path));
            if let Ok(new_path) = std::env::join_paths(paths) {
                command.env("PATH", new_path);
            }
        }
        if let Some(current_dir) = &self.current_dir {
            command.current_dir(current_dir);
        }
        command.args(args);
        command
    }
}

#[cfg(test)]
mod tests {
    use std::fs;

    use super::*;
    use crate::testing::env_mock;

    #[test]
    fn current_origin_url_parses_output() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            echo "git@github.com:owner/repo.git"
            "#,
        );

        let adapter = GitAdapter {
            mock_env_path: Some(bin_path.to_string_lossy().to_string()),
            ..Default::default()
        };

        let url = adapter.current_origin_url()?;
        assert_eq!(url, "git@github.com:owner/repo.git");
        Ok(())
    }

    #[test]
    fn remove_submodule_config_section_handles_success() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            exit 0
            "#,
        );

        let adapter = GitAdapter {
            mock_env_path: Some(bin_path.to_string_lossy().to_string()),
            ..Default::default()
        };

        adapter.remove_submodule_config_section("test-submodule")?;
        Ok(())
    }

    #[test]
    fn remove_submodule_config_section_handles_no_such_section()
    -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            echo "No such section" >&2
            exit 1
            "#,
        );

        let adapter = GitAdapter {
            mock_env_path: Some(bin_path.to_string_lossy().to_string()),
            ..Default::default()
        };

        adapter.remove_submodule_config_section("test-submodule")?;
        Ok(())
    }

    #[test]
    fn remove_submodule_module_dir_removes_directory() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;

        let modules_dir = temp_dir.path().join(".git").join("modules").join("test-submodule");
        fs::create_dir_all(&modules_dir)?;
        assert!(modules_dir.exists());

        let adapter =
            GitAdapter { current_dir: Some(temp_dir.path().to_path_buf()), ..Default::default() };

        adapter.remove_submodule_module_dir("test-submodule")?;
        assert!(!modules_dir.exists());
        Ok(())
    }

    #[test]
    fn delete_submodule_worktree_executes_correct_commands()
    -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("args.txt");
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                "#,
                args_file.display()
            ),
        );

        let adapter = GitAdapter {
            mock_env_path: Some(bin_path.to_string_lossy().to_string()),
            ..Default::default()
        };

        adapter.delete_submodule_worktree("test-submodule")?;

        let executed_args = fs::read_to_string(args_file)?;
        let mut lines = executed_args.lines();
        assert_eq!(
            lines.next().ok_or("missing first line")?.trim(),
            "submodule deinit -f test-submodule"
        );
        assert_eq!(lines.next().ok_or("missing second line")?.trim(), "rm -f -r test-submodule");
        Ok(())
    }
}
