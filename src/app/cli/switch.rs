//! CLI input contract for the `switch` command.

use clap::Args;

use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Args)]
pub struct SwitchArgs {
    /// Profile to switch to (personal/p, work/w).
    pub profile: String,
}

pub fn run(args: SwitchArgs) -> Result<(), AppError> {
    let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
    commands::switch::execute(&ctx, &args.profile)
}
