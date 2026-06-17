//! Build the coder intermediate entities from their manifests.
//!
//! Invoked during provisioning of the coder role so the intermediate AGENTS.md and
//! skills directory exist before the role symlinks agent tools to them.

use crate::app::AppContext;
use crate::coder::{self, Selectable};
use crate::error::AppError;

/// Rebuild both intermediate entities, surfacing any version-skew warnings.
pub fn execute(ctx: &AppContext) -> Result<(), AppError> {
    for kind in [Selectable::Agents, Selectable::Skills] {
        let selection = coder::rebuild_from_manifest(kind, &ctx.host_fs, &ctx.home_dir)?;
        for name in &selection.unknown_disabled {
            eprintln!(
                "warning: '{name}' is disabled in the {} manifest but not in the current catalog; ignoring",
                kind.label()
            );
        }
    }
    Ok(())
}
