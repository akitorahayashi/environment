//! Version source from Cargo package metadata.

use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

pub struct CargoPkgVersion;

impl VersionSource for CargoPkgVersion {
    fn current_version(&self) -> Result<String, AppError> {
        Ok(env!("CARGO_PKG_VERSION").to_string())
    }

    fn latest_version(&self) -> Result<String, AppError> {
        // Version checking against remote is deferred to phase 3.
        Err(AppError::VersionCheck("remote version check not yet implemented".to_string()))
    }

    fn needs_update(&self, current: &str, latest: &str) -> bool {
        match (semver::Version::parse(current), semver::Version::parse(latest)) {
            (Ok(cur), Ok(lat)) => lat > cur,
            _ => current != latest,
        }
    }

    fn run_upgrade(&self) -> Result<(), AppError> {
        Err(AppError::VersionCheck("upgrade not yet implemented".to_string()))
    }
}
