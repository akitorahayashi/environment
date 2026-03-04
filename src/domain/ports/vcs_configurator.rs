//! VCS configuration port — interface for setting global VCS identity.

use crate::domain::error::AppError;

/// Configures global VCS identity (user name and email).
pub trait VcsConfigurator {
    /// Set global user identity.
    fn set_identity(&self, name: &str, email: &str) -> Result<(), AppError>;

    /// Get current global user identity, if configured.
    fn get_identity(&self) -> Result<(String, String), AppError>;

    /// Whether this VCS tool is available on the system.
    fn is_available(&self) -> bool;

    /// VCS tool name for display (e.g., "git", "jj").
    fn tool_name(&self) -> &'static str;
}
