//! CLI input contract for the `make` command.

use clap::Args;

use crate::error::AppError;
use crate::provisioning::profile;

#[derive(Args)]
pub struct MakeArgs {
    /// Ansible tags to run (e.g., rust, python, pipx, shell, br-c).
    #[arg(required = true, num_args = 1..)]
    pub tags: Vec<String>,

    /// Profile to use (global, macbook/mbk, mac-mini/mmn).
    #[arg(short = 'p', long, default_value = "global")]
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
    for tag in args.tags {
        crate::make(profile, &tag, args.overwrite, args.verbose)?;
    }
    Ok(())
}
