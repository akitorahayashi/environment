//! Delete all labels from a repository.

use clap::Args;

use crate::adapters::{gh, git};
use crate::domain::repo_target;

#[derive(Args)]
pub struct LabelsResetArgs {
    /// Target repository in [HOST/]OWNER/REPO format.
    #[arg(short = 'R', long = "repo")]
    pub repo: Option<String>,
}

pub fn run(args: LabelsResetArgs) -> Result<(), Box<dyn std::error::Error>> {
    let git_adapter = git::GitAdapter::default();
    let origin_url = args.repo.is_none().then(|| git_adapter.current_origin_url()).transpose()?;
    let repo = repo_target::resolve_repo_ref(args.repo.as_deref(), origin_url.as_deref())?;

    let gh_adapter = gh::GhAdapter::default();
    let names = gh_adapter.list_label_names(&repo)?;

    if names.is_empty() {
        println!("No labels to delete in {}.", repo.as_gh_repo_arg());
        return Ok(());
    }

    for name in names {
        println!("Deleting label {name} from {}...", repo.as_gh_repo_arg());
        gh_adapter.delete_label(&repo, &name)?;
    }

    println!("Deleted all labels from {}.", repo.as_gh_repo_arg());
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::app::commands::gh;
    use crate::testing::env_mock;
    use serial_test::serial;
    use std::fs;

    #[test]
    #[serial]
    fn resets_all_labels_successfully() -> Result<(), Box<dyn std::error::Error>> {
        let test_env = gh::setup_gh_labels_command_test_environment()?;
        env_mock::create_mock_bin(
            "gh",
            test_env.temp_dir(),
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo "bugs\nfeats"
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        );

        run(LabelsResetArgs { repo: None })?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(gh_cmds.contains("label delete bugs"));
        assert!(gh_cmds.contains("label delete feats"));

        Ok(())
    }

    #[test]
    #[serial]
    fn skips_reset_if_no_labels() -> Result<(), Box<dyn std::error::Error>> {
        let test_env = gh::setup_gh_labels_command_test_environment()?;
        env_mock::create_mock_bin(
            "gh",
            test_env.temp_dir(),
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo ""
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        );

        run(LabelsResetArgs { repo: Some("owner/repo".to_string()) })?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(!gh_cmds.contains("label delete"));

        Ok(())
    }
}
