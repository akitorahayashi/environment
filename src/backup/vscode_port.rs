//! VSCode port — interface for interacting with the VSCode CLI.

use crate::error::AppError;

/// Interacts with the VSCode CLI.
pub trait VscodePort {
    /// List installed extensions.
    fn list_extensions(&self) -> Result<Vec<String>, AppError>;
}
