//! Version source port.

use crate::domain::error::AppError;

/// Provides version information and update capabilities.
pub trait VersionSource {
    /// Get current installed version.
    fn current_version(&self) -> Result<String, AppError>;

    /// Get latest available version.
    fn latest_version(&self) -> Result<String, AppError>;

    /// Check if update is needed.
    fn needs_update(&self, current: &str, latest: &str) -> bool;

    /// Execute the update process.
    fn run_upgrade(&self) -> Result<(), AppError>;
}
