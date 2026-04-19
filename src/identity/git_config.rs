//! Git configuration port — interface for setting global Git identity.

use crate::error::AppError;

/// Configures global Git identity (user name and email).
pub trait GitPort {
    /// Set global user identity.
    fn set_identity(&self, name: &str, email: &str) -> Result<(), AppError>;

    /// Get current global user identity, if configured.
    fn get_identity(&self) -> Result<(String, String), AppError>;

    /// Whether git is available on the system.
    fn is_available(&self) -> bool;
}
