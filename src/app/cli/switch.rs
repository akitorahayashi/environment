//! CLI input contract for the `switch` command.

use clap::Args;

use crate::app::api;
use crate::domain::error::AppError;
use crate::domain::identity;

#[derive(Args)]
pub struct SwitchArgs {
    /// Identity to switch to (personal/p, work/w).
    pub identity: String,
}

pub fn run(args: SwitchArgs) -> Result<(), AppError> {
    let identity = identity::resolve_switch_identity(&args.identity).ok_or_else(|| {
        AppError::InvalidIdentity(format!(
            "invalid identity '{}'. Valid: personal (p), work (w)",
            args.identity
        ))
    })?;
    api::switch(identity)
}
