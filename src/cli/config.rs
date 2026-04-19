//! CLI input contract for the `config` command.

use clap::Subcommand;

use crate::error::AppError;

#[derive(Subcommand)]
pub enum ConfigCommand {
    /// Deploy role configs to ~/.config/mev/roles/.
    #[command(visible_alias = "dp")]
    Deploy {
        /// Role name to deploy config for. If omitted, deploys all roles.
        role: Option<String>,

        /// Overwrite existing config with package defaults.
        #[arg(short, long)]
        overwrite: bool,
    },
}

pub fn run(cmd: ConfigCommand) -> Result<(), AppError> {
    match cmd {
        ConfigCommand::Deploy { role, overwrite } => crate::config_deploy(role, overwrite),
    }
}
