//! CLI input contract for the `identity` command.

use clap::Subcommand;

use crate::error::AppError;

#[derive(Subcommand)]
pub enum IdentityCommand {
    /// Display current Git identity configuration.
    Show,

    /// Set Git identity configuration interactively.
    Set,
}

pub fn run(cmd: IdentityCommand) -> Result<(), AppError> {
    match cmd {
        IdentityCommand::Show => crate::identity_show(),
        IdentityCommand::Set => crate::identity_set(),
    }
}
