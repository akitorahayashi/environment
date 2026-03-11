//! GitHub CLI adapter.

use std::process::Command;

use crate::adapters::process;
use crate::domain::label_catalog::LabelSpec;
use crate::domain::repository_ref::RepositoryRef;

pub fn list_label_names(repo: &RepositoryRef) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let output = process::run_output(
        build_gh_command(
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

pub fn delete_label(
    repo: &RepositoryRef,
    label_name: &str,
) -> Result<(), Box<dyn std::error::Error>> {
    process::run_status(
        build_gh_command(&["label", "delete", label_name, "--yes"], repo),
        &format!("gh label delete {label_name} --repo {}", repo.as_gh_repo_arg()),
    )
}

pub fn create_label(
    repo: &RepositoryRef,
    label: &LabelSpec,
) -> Result<(), Box<dyn std::error::Error>> {
    process::run_status(
        build_gh_command(
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

fn build_gh_command(args: &[&str], repo: &RepositoryRef) -> Command {
    let mut command = Command::new("gh");
    command.args(args);
    command.args(["--repo", &repo.as_gh_repo_arg()]);
    command
}
