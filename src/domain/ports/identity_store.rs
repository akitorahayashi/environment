//! Configuration storage port.

use std::path::Path;

use crate::domain::error::AppError;
use crate::domain::vcs_identity::{SwitchIdentity, VcsIdentity};

/// Persists and retrieves VCS identity configuration.
pub trait IdentityStore {
    /// Check if identity configuration file exists.
    fn exists(&self) -> bool;

    /// Load the full identity configuration.
    fn load(&self) -> Result<IdentityState, AppError>;

    /// Save the full identity configuration.
    fn save(&self, state: &IdentityState) -> Result<(), AppError>;

    /// Get the VCS identity for the given switch target.
    fn get_identity(&self, identity: SwitchIdentity) -> Result<Option<VcsIdentity>, AppError>;

    /// Get the identity configuration file path.
    fn identity_path(&self) -> &Path;
}

/// Top-level identity model stored on disk.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct IdentityState {
    pub personal: VcsIdentity,
    pub work: VcsIdentity,
}
