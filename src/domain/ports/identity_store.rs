//! Configuration storage port.

use std::path::Path;

use crate::domain::error::AppError;
use crate::domain::identity::{Identity, IdentityScope};

/// Persists and retrieves Git identity configuration.
pub trait IdentityStore {
    /// Check if identity configuration file exists.
    fn exists(&self) -> bool;

    /// Load the full identity configuration.
    fn load(&self) -> Result<IdentityState, AppError>;

    /// Save the full identity configuration.
    fn save(&self, state: &IdentityState) -> Result<(), AppError>;

    /// Get the identity for the given switch target.
    fn get_identity(&self, identity: IdentityScope) -> Result<Option<Identity>, AppError>;

    /// Get the identity configuration file path.
    fn identity_path(&self) -> &Path;
}

/// Top-level identity model stored on disk.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct IdentityState {
    #[serde(default, deserialize_with = "deserialize_identity_option")]
    pub personal: Option<Identity>,
    #[serde(default, deserialize_with = "deserialize_identity_option")]
    pub work: Option<Identity>,
}

fn deserialize_identity_option<'de, D>(deserializer: D) -> Result<Option<Identity>, D::Error>
where
    D: serde::Deserializer<'de>,
{
    use crate::domain::identity::RawIdentity;
    use serde::Deserialize;
    let raw: Option<RawIdentity> = Option::deserialize(deserializer)?;
    Ok(raw.and_then(|r| Identity::try_from(r).ok()))
}
