//! Git CLI adapter.

use crate::domain::DomainError;
use clap::Subcommand;

#[derive(Subcommand)]
pub enum GitCommand {
    /// Delete a git submodule completely.
    DeleteSubmodule(crate::app::commands::git::delete_submodule::DeleteSubmoduleArgs),
}

pub fn run(cmd: GitCommand) -> Result<(), DomainError> {
    match cmd {
        GitCommand::DeleteSubmodule(args) => crate::app::commands::git::delete_submodule::run(args),
    }
}
