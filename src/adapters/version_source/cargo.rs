//! Version source from Cargo package metadata with GitHub release check and pipx upgrade.

use std::process::Command;

use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

const GITHUB_RELEASES_URL: &str = "https://api.github.com/repos/akitorahayashi/mev/releases/latest";

pub struct CargoVersion;

impl VersionSource for CargoVersion {
    fn current_version(&self) -> Result<String, AppError> {
        Ok(env!("CARGO_PKG_VERSION").to_string())
    }

    fn latest_version(&self) -> Result<String, AppError> {
        let response = ureq::get(GITHUB_RELEASES_URL)
            .set("Accept", "application/vnd.github.v3+json")
            .set("User-Agent", "mev-cli")
            .call()
            .map_err(|e| match e {
                ureq::Error::Status(code, _) => AppError::VersionCheck(format!(
                    "failed to fetch latest version from GitHub (status: {code})"
                )),
                ureq::Error::Transport(err) => {
                    AppError::VersionCheck(format!("failed to fetch latest version: {err}"))
                }
            })?;

        let data: serde_json::Value = response
            .into_json()
            .map_err(|e| AppError::VersionCheck(format!("failed to parse release data: {e}")))?;

        let tag = data["tag_name"]
            .as_str()
            .ok_or_else(|| AppError::VersionCheck("no tag_name in release data".to_string()))?;

        Ok(tag.trim_start_matches('v').to_string())
    }

    fn needs_update(&self, current: &str, latest: &str) -> bool {
        match (semver::Version::parse(current), semver::Version::parse(latest)) {
            (Ok(cur), Ok(lat)) => lat > cur,
            _ => current != latest,
        }
    }

    fn run_upgrade(&self) -> Result<(), AppError> {
        // Upgrade strategy is intentionally tied to pipx.
        // This project is installed as a pipx-managed unit (Python venv + bundled
        // Rust binaries + packaged assets such as ansible content), so the updater
        // must refresh the same installation boundary. A cargo-based self-update
        // would only target Rust artifacts and can diverge from the pipx runtime.
        println!("Upgrading mev via pipx...");

        let status = Command::new("pipx").args(["upgrade", "mev"]).status().map_err(|e| {
            if e.kind() == std::io::ErrorKind::NotFound {
                AppError::VersionCheck(
                    "pipx not found. Please ensure pipx is installed.".to_string(),
                )
            } else {
                AppError::VersionCheck(format!("failed to run pipx: {e}"))
            }
        })?;

        if !status.success() {
            return Err(AppError::VersionCheck(format!(
                "pipx upgrade failed with exit code {}",
                status.code().unwrap_or(-1)
            )));
        }

        Ok(())
    }
}
