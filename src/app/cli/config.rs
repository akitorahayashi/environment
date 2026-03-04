//! CLI input contract for the `config` command.

use clap::Subcommand;

use crate::adapters::package_assets::ansible_asset_locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Subcommand)]
pub enum ConfigCommand {
    /// Display current VCS identity configuration.
    Show,

    /// Set VCS identity configuration interactively.
    Set,

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
        ConfigCommand::Show => {
            let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
            commands::config::show(&ctx)
        }
        ConfigCommand::Set => {
            let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
            commands::config::set(&ctx)
        }
        ConfigCommand::Create { role, overwrite } => {
            let ansible_dir = ansible_asset_locator::locate_ansible_dir()?;
            let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
            commands::config::create(&ctx, role, overwrite)
        }
    }
}
