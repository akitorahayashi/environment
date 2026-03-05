//! CLI input contract for the `switch` command.

use clap::Args;

use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::vcs_identity;

#[derive(Args)]
pub struct SwitchArgs {
    /// Identity to switch to (personal/p, work/w).
    pub identity: String,
}

pub fn run(args: SwitchArgs) -> Result<(), AppError> {
    let identity = vcs_identity::resolve_switch_identity(&args.identity).ok_or_else(|| {
        AppError::InvalidIdentity(format!(
            "invalid identity '{}'. Valid: personal (p), work (w)",
            args.identity
        ))
    })?;
    let ctx = DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))?;
    commands::switch::execute(&ctx, identity)
}
