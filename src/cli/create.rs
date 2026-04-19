//! CLI input contract for the `create` command.

use clap::Args;

use crate::error::AppError;
use crate::provisioning::profile;

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
    let profile = profile::validate_hardware_profile(&args.profile)?;
    crate::create(profile, args.overwrite, args.verbose)
}
