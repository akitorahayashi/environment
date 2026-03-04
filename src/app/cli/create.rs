//! CLI input contract for the `create` command.

use clap::Args;

use crate::adapters::ansible::locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::profile;

#[derive(Args)]
pub struct CreateArgs {
    /// Profile to create (macbook/mbk, mac-mini/mmn).
    pub profile: String,

    /// Overwrite existing role configs with package defaults.
    #[arg(short, long)]
    pub overwrite: bool,

    /// Enable verbose output.
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn run(args: CreateArgs) -> Result<(), AppError> {
    let resolved = profile::validate_machine_profile(&args.profile)?;
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::create::execute(&ctx, resolved, args.overwrite, args.verbose)
}
