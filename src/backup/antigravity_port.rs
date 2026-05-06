//! Antigravity port — interface for interacting with the Antigravity CLI.

use crate::error::AppError;

/// Interacts with the Antigravity CLI.
pub trait AntigravityPort {
    /// List installed extensions.
    fn list_extensions(&self) -> Result<Vec<String>, AppError>;
}
