//! Jujutsu configuration port — interface for setting global Jujutsu identity.

use crate::domain::error::AppError;

/// Configures global Jujutsu identity (user name and email).
pub trait JjPort {
    /// Set global user identity.
    fn set_identity(&self, name: &str, email: &str) -> Result<(), AppError>;

    /// Get current global user identity, if configured.
    fn get_identity(&self) -> Result<(String, String), AppError>;

    /// Whether jj is available on the system.
    fn is_available(&self) -> bool;
}
