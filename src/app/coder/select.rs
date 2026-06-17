//! `config select` orchestration: present the toggle TUI and apply the result.

use crate::app::AppContext;
use crate::coder::{self, Selectable};
use crate::error::AppError;

/// Run the interactive selection for one selectable kind.
pub fn execute(ctx: &AppContext, kind: Selectable) -> Result<(), AppError> {
    let state = coder::current_state(kind, &ctx.host_fs, &ctx.home_dir)?;

    for name in &state.unknown_disabled {
        eprintln!(
            "warning: '{name}' is disabled in the {} manifest but not in the current catalog; ignoring",
            kind.label()
        );
    }

    let prompt = format!("Select {} to enable", kind.label());
    let chosen = coder::tui::toggle(&prompt, &state.entries)?;

    let Some(enabled) = chosen else {
        eprintln!("No changes made.");
        return Ok(());
    };

    coder::apply_selection(kind, &ctx.host_fs, &ctx.home_dir, &enabled)?;
    eprintln!("Updated {} ({} enabled).", kind.label(), enabled.len());

    Ok(())
}
