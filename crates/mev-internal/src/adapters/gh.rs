//! GitHub CLI adapter.

use std::process::Command;

use crate::adapters::process;
use crate::domain::DomainError;
use crate::domain::label_catalog::LabelSpec;
use crate::domain::repository_ref::RepositoryRef;

#[derive(Default)]
pub struct GhAdapter {
    pub mock_env_path: Option<String>,
}

impl GhAdapter {
    pub fn list_label_names(&self, repo: &RepositoryRef) -> Result<Vec<String>, DomainError> {
        let output = process::run_output(
            self.build_gh_command(
                &["label", "list", "--limit", "9999", "--json", "name", "--jq", ".[].name"],
                repo,
            ),
            &format!("gh label list --repo {}", repo.as_gh_repo_arg()),
        )?;

        Ok(String::from_utf8(output.stdout)?
            .lines()
            .map(str::trim)
            .filter(|line| !line.is_empty())
            .map(ToOwned::to_owned)
            .collect())
    }

    pub fn delete_label(&self, repo: &RepositoryRef, label_name: &str) -> Result<(), DomainError> {
        process::run_status(
            self.build_gh_command(&["label", "delete", label_name, "--yes"], repo),
            &format!("gh label delete {label_name} --repo {}", repo.as_gh_repo_arg()),
        )
    }

    pub fn create_label(&self, repo: &RepositoryRef, label: &LabelSpec) -> Result<(), DomainError> {
        process::run_status(
            self.build_gh_command(
                &[
                    "label",
                    "create",
                    &label.name,
                    "--description",
                    &label.description,
                    "--color",
                    &label.color,
                ],
                repo,
            ),
            &format!("gh label create {} --repo {}", label.name, repo.as_gh_repo_arg()),
        )
    }

    fn build_gh_command(&self, args: &[&str], repo: &RepositoryRef) -> Command {
        let mut command = Command::new("gh");
        if let Some(env_path) = &self.mock_env_path {
            let original_path = std::env::var_os("PATH").unwrap_or_default();
            let mut paths = std::env::split_paths(&original_path).collect::<Vec<_>>();
            paths.insert(0, std::path::PathBuf::from(env_path));
            if let Ok(new_path) = std::env::join_paths(paths) {
                command.env("PATH", new_path);
            }
        }
        command.args(args);
        command.args(["--repo", &repo.as_gh_repo_arg()]);
        command
    }
}

#[cfg(test)]
mod tests {
    use std::fs;

    use serial_test::serial;

    use super::*;
    use crate::testing::env_mock;

    #[test]
    #[serial]
    fn list_label_names_parses_output() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let bin_path = env_mock::create_mock_bin(
            "gh",
            &temp_dir,
            r#"#!/bin/sh
            echo "bug\nfeature\nhelp wanted"
            "#,
        );

        let repo = RepositoryRef::from_repo_arg("owner/repo")?;
        let adapter = GhAdapter { mock_env_path: Some(bin_path.to_string_lossy().to_string()) };
        let labels = adapter.list_label_names(&repo)?;
        assert_eq!(labels, vec!["bug", "feature", "help wanted"]);
        Ok(())
    }

    #[test]
    #[serial]
    fn create_label_executes_correct_command() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("args.txt");
        let bin_path = env_mock::create_mock_bin(
            "gh",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" > "{}"
                "#,
                args_file.display()
            ),
        );

        let repo = RepositoryRef::from_repo_arg("owner/repo")?;
        let label = LabelSpec {
            name: "bug".to_string(),
            description: "Something isn't working".to_string(),
            color: "d73a4a".to_string(),
        };

        let adapter = GhAdapter { mock_env_path: Some(bin_path.to_string_lossy().to_string()) };
        adapter.create_label(&repo, &label)?;

        let executed_args = fs::read_to_string(args_file)?;
        assert_eq!(
            executed_args.trim(),
            "label create bug --description Something isn't working --color d73a4a --repo owner/repo"
        );
        Ok(())
    }

    #[test]
    #[serial]
    fn delete_label_executes_correct_command() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("args.txt");
        let bin_path = env_mock::create_mock_bin(
            "gh",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" > "{}"
                "#,
                args_file.display()
            ),
        );

        let repo = RepositoryRef::from_repo_arg("owner/repo")?;
        let adapter = GhAdapter { mock_env_path: Some(bin_path.to_string_lossy().to_string()) };
        adapter.delete_label(&repo, "bug")?;

        let executed_args = fs::read_to_string(args_file)?;
        assert_eq!(executed_args.trim(), "label delete bug --yes --repo owner/repo");
        Ok(())
    }
}
