//! CLI input contract for the `create` command.

use clap::Args;

use crate::adapters::package_assets::ansible_asset_locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::profile;

#[derive(Args)]
pub struct CreateArgs {
    /// Profile to create (macbook/mbk, mac-mini/mmn).
    pub profile: String,

    /// Enable verbose output.
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn run(args: CreateArgs) -> Result<(), AppError> {
    let resolved = profile::validate_machine_profile(&args.profile)?;
    let ansible_dir = ansible_asset_locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::create::execute(&ctx, resolved, args.verbose)
}
