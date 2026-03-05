//! CLI input contract for the `switch` command.

use clap::Args;

use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Args)]
pub struct SwitchArgs {
    /// Identity to switch to (personal/p, work/w).
    pub identity: String,
}

pub fn run(args: SwitchArgs) -> Result<(), AppError> {
    let ctx = DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))?;
    commands::switch::execute(&ctx, &args.identity)
}
