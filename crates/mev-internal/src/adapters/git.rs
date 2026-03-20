//! Git CLI adapter.

use std::fs;
use std::path::Path;
use std::process::Command;

use crate::adapters::process;

pub fn delete_submodule_worktree(submodule_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    process::run_status(
        git_command(["submodule", "deinit", "-f", submodule_path]),
        &format!("git submodule deinit -f {submodule_path}"),
    )?;

    process::run_status(
        git_command(["rm", "-f", "-r", submodule_path]),
        &format!("git rm -f -r {submodule_path}"),
    )?;

    Ok(())
}

pub fn remove_submodule_module_dir(submodule_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    let modules_path = Path::new(".git").join("modules").join(submodule_path);
    if modules_path.exists() {
        fs::remove_dir_all(&modules_path)?;
    }
    Ok(())
}

pub fn remove_submodule_config_section(
    submodule_path: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    let output = process::run_output(
        git_command(["config", "--remove-section", &format!("submodule.{submodule_path}")]),
        &format!("git config --remove-section submodule.{submodule_path}"),
    );

    match output {
        Ok(_) => Ok(()),
        Err(err) if err.to_string().contains("No such section") => Ok(()),
        Err(err) => Err(err),
    }
}

pub fn current_origin_url() -> Result<String, Box<dyn std::error::Error>> {
    let output = process::run_output(
        git_command(["remote", "get-url", "origin"]),
        "git remote get-url origin",
    )?;
    Ok(String::from_utf8(output.stdout)?.trim().to_owned())
}

fn git_command<const N: usize, S>(args: [S; N]) -> Command
where
    S: AsRef<std::ffi::OsStr>,
{
    let mut command = Command::new("git");
    command.args(args);
    command
}

#[cfg(test)]
mod tests {
    use serial_test::serial;

    use std::fs;

    use super::*;
    use crate::testing::env_mock;

    #[test]
    #[serial(env_path)]
    fn current_origin_url_parses_output() {
        let temp_dir = tempfile::tempdir().unwrap();
        let _path_guard = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            echo "git@github.com:owner/repo.git"
            "#,
        );

        let url = current_origin_url().expect("current_origin_url should succeed");
        assert_eq!(url, "git@github.com:owner/repo.git");
    }

    #[test]
    #[serial(env_path)]
    fn remove_submodule_config_section_handles_success() {
        let temp_dir = tempfile::tempdir().unwrap();
        let _path_guard = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            exit 0
            "#,
        );

        let result = remove_submodule_config_section("test-submodule");
        assert!(result.is_ok());
    }

    #[test]
    #[serial(env_path)]
    fn remove_submodule_config_section_handles_no_such_section() {
        let temp_dir = tempfile::tempdir().unwrap();
        let _path_guard = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            r#"#!/bin/sh
            echo "No such section" >&2
            exit 1
            "#,
        );

        let result = remove_submodule_config_section("test-submodule");
        assert!(result.is_ok());
    }

    #[test]
    #[serial(env_dir)]
    fn remove_submodule_module_dir_removes_directory() {
        let temp_dir = tempfile::tempdir().unwrap();
        let _dir_guard = env_mock::DirGuard::new(temp_dir.path());

        let modules_dir = Path::new(".git").join("modules").join("test-submodule");
        fs::create_dir_all(&modules_dir).unwrap();
        assert!(modules_dir.exists());

        remove_submodule_module_dir("test-submodule").unwrap();
        assert!(!modules_dir.exists());
    }

    #[test]
    #[serial(env_path)]
    fn delete_submodule_worktree_executes_correct_commands() {
        let temp_dir = tempfile::tempdir().unwrap();
        let args_file = temp_dir.path().join("args.txt");
        let _path_guard = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                "#,
                args_file.display()
            ),
        );

        delete_submodule_worktree("test-submodule")
            .expect("delete_submodule_worktree should succeed");

        let executed_args = fs::read_to_string(args_file).unwrap();
        let mut lines = executed_args.lines();
        assert_eq!(lines.next().unwrap().trim(), "submodule deinit -f test-submodule");
        assert_eq!(lines.next().unwrap().trim(), "rm -f -r test-submodule");
    }
}
