//! Configuration path resolution.
//!
//! The base path is `~/.config/` — the project convention for macOS.
//! Ansible roles reference `local_config_root` as an extra var and expect
//! `~/.config/menv/roles/`, so this path must not change.

use std::path::PathBuf;

use crate::domain::error::AppError;

fn config_base() -> Result<PathBuf, AppError> {
    dirs::home_dir()
        .map(|h| h.join(".config"))
        .ok_or_else(|| AppError::Config("home directory could not be resolved".to_string()))
}

/// Default path to the mev configuration file.
pub fn default_config_path() -> Result<PathBuf, AppError> {
    Ok(config_base()?.join("menv").join("config.json"))
}

/// Default path to the local config root for deployed role configs.
pub fn local_config_root() -> Result<PathBuf, AppError> {
    Ok(config_base()?.join("menv").join("roles"))
}
