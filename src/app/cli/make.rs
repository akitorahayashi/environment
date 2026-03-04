//! CLI input contract for the `make` command.

use clap::Args;

use crate::adapters::package_assets::ansible_asset_locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::profile;

#[derive(Args)]
pub struct MakeArgs {
    /// Ansible tag to run (e.g., rust, python-tools, shell, brew-cask).
    pub tag: String,

    /// Profile to use (common, macbook/mbk, mac-mini/mmn).
    #[arg(default_value = "common")]
    pub profile: String,

    /// Enable verbose output.
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn run(args: MakeArgs) -> Result<(), AppError> {
    let resolved = profile::validate_profile(&args.profile)?;
    let ansible_dir = ansible_asset_locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::make::execute(&ctx, resolved, &args.tag, args.verbose)
}
