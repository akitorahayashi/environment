//! CLI input contract for the `identity` command.

use clap::Subcommand;

use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Subcommand)]
pub enum IdentityCommand {
    /// Display current VCS identity configuration.
    Show,

    /// Set VCS identity configuration interactively.
    Set,
}

pub fn run(cmd: IdentityCommand) -> Result<(), AppError> {
    match cmd {
        IdentityCommand::Show => {
            let ctx =
                DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))?;
            commands::identity::show(&ctx)
        }
        IdentityCommand::Set => {
            let ctx =
                DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))?;
            commands::identity::set(&ctx)
        }
    }
}
