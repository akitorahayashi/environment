//! Version source from package metadata with pipx upgrade execution.

use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

pub struct PipxVersionSource;

impl VersionSource for PipxVersionSource {
    fn current_version(&self) -> Result<String, AppError> {
        Ok(env!("CARGO_PKG_VERSION").to_string())
    }

    fn run_upgrade(&self) -> Result<(), AppError> {
        // Upgrade strategy is intentionally tied to pipx.
        // This project is installed as a pipx-managed unit (Python venv + bundled
        // Rust binaries + packaged assets such as ansible content), so the updater
        // must refresh the same installation boundary. A cargo-based self-update
        // would only target Rust artifacts and can diverge from the pipx runtime.
        println!("Upgrading {} via pipx...", env!("CARGO_PKG_NAME"));

        let status = Command::new("pipx")
            .args(["upgrade", env!("CARGO_PKG_NAME")])
            .status()
            .map_err(|e| {
                if e.kind() == std::io::ErrorKind::NotFound {
                    AppError::Update("pipx not found. Please ensure pipx is installed.".to_string())
                } else {
                    AppError::Update(format!("failed to run pipx: {e}"))
                }
            })?;

        if !status.success() {
            return Err(AppError::Update(format!(
                "pipx upgrade failed with exit code {}",
                status.code().unwrap_or(-1)
            )));
        }

        Ok(())
    }
}
