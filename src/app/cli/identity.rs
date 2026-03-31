//! CLI input contract for the `identity` command.

use clap::Subcommand;

use crate::app::api;
use crate::domain::error::AppError;

#[derive(Subcommand)]
pub enum IdentityCommand {
    /// Display current Git identity configuration.
    Show,

    /// Set Git identity configuration interactively.
    Set,
}

pub fn run(cmd: IdentityCommand) -> Result<(), AppError> {
    match cmd {
        IdentityCommand::Show => api::identity_show(),
        IdentityCommand::Set => api::identity_set(),
    }
}
