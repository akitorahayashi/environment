//! Multi-select presentation for toggling coder selectables.
//!
//! Space toggles an entry, enter confirms, esc cancels. Entries already enabled
//! start checked. Returns the names the user chose to keep enabled, or `None` if
//! the user cancelled.

use inquire::MultiSelect;

use crate::coder::EntryState;
use crate::error::AppError;

/// Present the entries and return the chosen-enabled names, or `None` on cancel.
pub fn toggle(prompt: &str, entries: &[EntryState]) -> Result<Option<Vec<String>>, AppError> {
    let options: Vec<String> = entries.iter().map(|e| e.name.clone()).collect();
    let default: Vec<usize> = entries
        .iter()
        .enumerate()
        .filter_map(|(i, e)| if e.enabled { Some(i) } else { None })
        .collect();

    let selection = MultiSelect::new(prompt, options)
        .with_default(&default)
        .with_help_message("space toggles, enter confirms, esc cancels")
        .prompt_skippable()
        .map_err(|e| AppError::Config(format!("selection prompt failed: {e}")))?;

    Ok(selection)
}
