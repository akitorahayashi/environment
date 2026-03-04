//! Stable library entrypoints for programmatic consumers.
//!
//! Each public function wires context creation to command execution.
//! `cli/` modules delegate here; external callers (tests, scripts) can
//! import these directly via `mev::api::*`.

use crate::adapters::ansible::locator;
use crate::adapters::version_source::cargo::CargoVersion;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

pub use crate::domain::backup::BackupTarget;
pub use crate::domain::config::VcsIdentity;
pub use crate::domain::error::AppError as Error;
pub use crate::domain::execution_plan::ExecutionPlan;
pub use crate::domain::ports::config_store::MevConfig;

// =============================================================================
// Create
// =============================================================================

/// Provision a complete development environment for the given profile.
pub fn create(profile: &str, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::create::execute(&ctx, profile, overwrite, verbose)
}

// =============================================================================
// Make
// =============================================================================

/// Run a single Ansible task by tag within a profile.
pub fn make(profile: &str, tag: &str, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::make::execute(&ctx, profile, tag, overwrite, verbose)
}

// =============================================================================
// List
// =============================================================================

/// Print the available tags, tag groups, and profiles.
pub fn list() -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::list::execute(&ctx)
}

// =============================================================================
// Config
// =============================================================================

/// Show current VCS identity configuration.
pub fn config_show() -> Result<(), AppError> {
    let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
    commands::config::show(&ctx)
}

/// Interactively set VCS identity configuration.
pub fn config_set() -> Result<(), AppError> {
    let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
    commands::config::set(&ctx)
}

/// Deploy role configuration files.
pub fn config_create(role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::config::create(&ctx, role, overwrite)
}

// =============================================================================
// Switch
// =============================================================================

/// Switch the global VCS identity between personal and work.
pub fn switch(profile: &str) -> Result<(), AppError> {
    let ctx = AppContext::for_config().map_err(|e| AppError::Config(e.to_string()))?;
    commands::switch::execute(&ctx, profile)
}

// =============================================================================
// Update
// =============================================================================

/// Check for and install updates to the mev CLI.
pub fn update() -> Result<(), AppError> {
    let source = CargoVersion;
    commands::update::execute(&source)
}

/// Update with a caller-supplied version source (test seam).
#[allow(dead_code)]
pub(crate) fn update_with_source(source: &dyn VersionSource) -> Result<(), AppError> {
    commands::update::execute(source)
}

// =============================================================================
// Backup
// =============================================================================

/// Backup a system setting or configuration target.
pub fn backup(target: &str) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::backup::execute(&ctx, target)
}
