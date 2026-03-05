//! CLI input contract for the `make` command.

use clap::Args;

use crate::adapters::ansible::locator;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::profile;

#[derive(Args)]
pub struct MakeArgs {
    /// Ansible tag to run (e.g., rust, python-tools, shell, brew-cask).
    pub tag: String,

    /// Profile to use (common, macbook/mbk, mac-mini/mmn).
    #[arg(short = 'p', long, default_value = "common")]
    pub profile: String,

    /// Overwrite existing role configs with package defaults.
    #[arg(short, long)]
    pub overwrite: bool,

    /// Enable verbose output.
    #[arg(short, long)]
    pub verbose: bool,
}

pub fn run(args: MakeArgs) -> Result<(), AppError> {
    let profile = profile::validate_profile(&args.profile)?;
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = DependencyContainer::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::make::execute(&ctx, profile, &args.tag, args.overwrite, args.verbose)
}
