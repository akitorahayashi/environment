//! Version source port.

use crate::error::AppError;

/// Provides version information and update execution.
pub trait VersionSource {
    /// Get current installed version.
    fn current_version(&self) -> Result<String, AppError>;

    /// Execute the update process.
    fn run_upgrade(&self) -> Result<(), AppError>;
}
