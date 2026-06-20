use clap::{Args, Subcommand};

use crate::error::AppError;

/// Internal subcommands delegated to `mev-vcs`.
#[derive(Subcommand)]
pub enum InternalCommand {
    /// Git operations.
    #[command(subcommand)]
    Git(GitCommand),

    /// GitHub CLI operations.
    #[command(subcommand)]
    Gh(GhCommand),
}

#[derive(Subcommand)]
pub enum GitCommand {
    /// Clone one or more repositories sequentially.
    Clone(CloneArgs),

    /// Delete one or more local branches after updating main.
    DeleteBranches(DeleteBranchesArgs),

    /// Delete a git submodule completely.
    DeleteSubmodule(DeleteSubmoduleArgs),
}

#[derive(Args)]
pub struct CloneArgs {
    /// Repository URLs to clone in order, optionally mixed with `git clone` flags
    /// (e.g. `--depth 1`) that are applied to every clone.
    #[arg(required = true, trailing_var_arg = true, allow_hyphen_values = true)]
    pub args: Vec<String>,
}

#[derive(Args)]
#[command(dont_delimit_trailing_values = true)]
pub struct DeleteBranchesArgs {
    /// Local branch names to delete, optionally followed by `-- <checkout-branch>`.
    #[arg(required = true, trailing_var_arg = true, allow_hyphen_values = true)]
    pub args: Vec<String>,
}

#[derive(Args)]
pub struct DeleteSubmoduleArgs {
    /// Relative path to the submodule.
    pub submodule_path: String,
}

#[derive(Subcommand)]
pub enum GhCommand {
    /// GitHub label operations.
    #[command(subcommand)]
    Labels(GhLabelsCommand),
}

#[derive(Subcommand)]
pub enum GhLabelsCommand {
    /// Delete all labels from the target repository.
    Reset(LabelsArgs),

    /// Deploy the bundled label catalog to the target repository.
    Deploy(LabelsArgs),
}

#[derive(Args)]
pub struct LabelsArgs {
    /// Target repository in [HOST/]OWNER/REPO format.
    #[arg(short = 'R', long = "repo")]
    pub repo: Option<String>,
}

pub fn run(command: InternalCommand) -> Result<(), AppError> {
    let result = match command {
        InternalCommand::Git(GitCommand::Clone(args)) => {
            mev_vcs::git::clone_repositories(&args.args)
        }
        InternalCommand::Git(GitCommand::DeleteBranches(args)) => {
            mev_vcs::git::delete_branches(&args.args)
        }
        InternalCommand::Git(GitCommand::DeleteSubmodule(args)) => {
            mev_vcs::git::delete_submodule(&args.submodule_path)
        }
        InternalCommand::Gh(GhCommand::Labels(GhLabelsCommand::Reset(args))) => {
            mev_vcs::gh::reset_labels(args.repo.as_deref())
        }
        InternalCommand::Gh(GhCommand::Labels(GhLabelsCommand::Deploy(args))) => {
            mev_vcs::gh::deploy_labels(args.repo.as_deref())
        }
    };

    result.map_err(|e| AppError::Config(e.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;
    use clap::CommandFactory;

    #[derive(clap::Parser)]
    struct ProbeCli {
        #[command(subcommand)]
        command: InternalCommand,
    }

    #[test]
    fn delete_branches_preserves_checkout_separator() {
        let matches = ProbeCli::command()
            .try_get_matches_from([
                "internal",
                "git",
                "delete-branches",
                "feature/a",
                "--",
                "develop",
            ])
            .unwrap();

        let args = matches
            .subcommand_matches("git")
            .and_then(|matches| matches.subcommand_matches("delete-branches"))
            .and_then(|matches| matches.get_many::<String>("args"))
            .unwrap()
            .map(String::as_str)
            .collect::<Vec<_>>();

        assert_eq!(args, ["feature/a", "--", "develop"]);
    }

    #[test]
    fn verify_internal_cli_shapes() {
        let cases: &[&[&str]] = &[
            &["internal", "gh", "labels", "deploy", "--help"],
            &["internal", "gh", "labels", "reset", "--help"],
            &["internal", "git", "clone", "--help"],
            &["internal", "git", "delete-branches", "--help"],
            &["internal", "git", "delete-submodule", "--help"],
        ];

        for args in cases {
            let err = ProbeCli::command().try_get_matches_from(*args).unwrap_err();
            assert_eq!(
                err.kind(),
                clap::error::ErrorKind::DisplayHelp,
                "Failed for args: {args:?}"
            );
        }
    }
}
