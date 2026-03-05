//! CLI input contract for the `config` command.

use clap::Subcommand;

use crate::adapters::ansible::locator;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Subcommand)]
pub enum ConfigCommand {
    /// Deploy role configs to ~/.config/mev/roles/.
    #[command(alias = "cr")]
    Create {
        /// Role name to deploy config for. If omitted, deploys all roles.
        role: Option<String>,

        /// Overwrite existing config with package defaults.
        #[arg(short, long)]
        overwrite: bool,
    },
}

pub fn run(cmd: ConfigCommand) -> Result<(), AppError> {
    match cmd {
        ConfigCommand::Create { role, overwrite } => {
            let ansible_dir = locator::locate_ansible_dir()?;
            let ctx = DependencyContainer::new(ansible_dir)
                .map_err(|e| AppError::Config(e.to_string()))?;
            commands::config::create(&ctx, role, overwrite)
        }
    }
}
