use clap::Subcommand;

use crate::app::internal;
use crate::error::AppError;

/// Internal subcommands delegated to `mev-internal` through app orchestration.
#[derive(Subcommand)]
pub enum InternalCommand {
    /// Git operations.
    #[command(subcommand)]
    Git(mev_internal::app::cli::git::GitCommand),

    /// GitHub CLI operations.
    #[command(subcommand)]
    Gh(mev_internal::app::cli::gh::GhCommand),
}

pub fn run(command: InternalCommand) -> Result<(), AppError> {
    match command {
        InternalCommand::Git(cmd) => internal::git::run(cmd),
        InternalCommand::Gh(cmd) => internal::gh::run(cmd),
    }
}
