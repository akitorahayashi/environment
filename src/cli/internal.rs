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

    /// Delete a git submodule completely.
    DeleteSubmodule(DeleteSubmoduleArgs),
}

#[derive(Args)]
pub struct CloneArgs {
    /// Repository URLs to clone in order.
    #[arg(required = true)]
    pub urls: Vec<String>,
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
            mev_vcs::git::clone_repositories(&args.urls)
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
    fn verify_internal_cli_shapes() {
        let cases: &[&[&str]] = &[
            &["internal", "gh", "labels", "deploy", "--help"],
            &["internal", "gh", "labels", "reset", "--help"],
            &["internal", "git", "clone", "--help"],
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
