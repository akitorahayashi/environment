//! CLI input contract for the `switch` command.

use clap::Args;

use crate::error::AppError;
use crate::identity::model;

#[derive(Args)]
pub struct SwitchArgs {
    /// Identity to switch to (personal/p, work/w).
    pub identity: String,
}

pub fn run(args: SwitchArgs) -> Result<(), AppError> {
    let identity = model::resolve_identity_scope(&args.identity).ok_or_else(|| {
        AppError::InvalidIdentityScope(format!(
            "invalid identity scope '{}'. Valid: personal (p), work (w)",
            args.identity
        ))
    })?;
    crate::switch_identity(identity)
}
