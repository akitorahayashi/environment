//! Configuration storage port.

use std::path::PathBuf;

use crate::domain::config::VcsIdentity;
use crate::domain::error::AppError;

/// Persists and retrieves VCS identity configuration.
pub trait ConfigStore {
    /// Check if configuration file exists.
    fn exists(&self) -> bool;

    /// Load the full configuration.
    fn load(&self) -> Result<MevConfig, AppError>;

    /// Save the full configuration.
    fn save(&self, config: &MevConfig) -> Result<(), AppError>;

    /// Get a specific VCS identity by profile name.
    fn get_identity(&self, profile: &str) -> Result<Option<VcsIdentity>, AppError>;

    /// Get the configuration file path.
    fn config_path(&self) -> PathBuf;
}

/// Top-level configuration model stored on disk.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct MevConfig {
    pub personal: VcsIdentity,
    pub work: VcsIdentity,
}
