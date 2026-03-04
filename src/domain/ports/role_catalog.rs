//! Role catalog port — resolves roles with configuration directories.

use crate::domain::error::AppError;

/// Provides role discovery for config deployment.
pub trait RoleCatalog {
    /// List roles that have a config directory.
    fn roles_with_config(&self) -> Result<Vec<String>, AppError>;
}
