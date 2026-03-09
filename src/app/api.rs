//! Stable library entrypoints for programmatic consumers.
//!
//! Each public function wires context creation to command execution.
//! `cli/` modules delegate here; external callers (tests, scripts) can
//! import these directly via `mev::api::*`.

use crate::adapters::ansible::locator;
use crate::adapters::version_source::install_script::InstallScriptVersionSource;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::ports::version_source::VersionSource;

pub use crate::domain::backup_target::BackupTarget;
pub use crate::domain::error::AppError as Error;
pub use crate::domain::execution_plan::ExecutionPlan;
pub use crate::domain::ports::identity_store::IdentityState;
pub use crate::domain::profile::Profile;
pub use crate::domain::vcs_identity::{SwitchIdentity, VcsIdentity};

// =============================================================================
// Create
// =============================================================================

/// Provision a complete development environment for the given profile.
pub fn create(profile: Profile, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::create::execute(&ctx, profile, overwrite, verbose)
}

// =============================================================================
// Make
// =============================================================================

/// Run a single Ansible task by tag within a profile.
pub fn make(profile: Profile, tag: &str, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::make::execute(&ctx, profile, tag, overwrite, verbose)
}

// =============================================================================
// List
// =============================================================================

/// Print the available tags, tag groups, and profiles.
pub fn list() -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::list::execute(&ctx)
}

// =============================================================================
// Config
// =============================================================================

/// Deploy role configuration files.
pub fn config_create(role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::config::create(&ctx, role, overwrite)
}

// =============================================================================
// Identity
// =============================================================================

/// Show current VCS identity configuration.
pub fn identity_show() -> Result<(), AppError> {
    let ctx = identity_context()?;
    commands::identity::show(&ctx)
}

/// Interactively set VCS identity configuration.
pub fn identity_set() -> Result<(), AppError> {
    let ctx = identity_context()?;
    commands::identity::set(&ctx)
}

// =============================================================================
// Switch
// =============================================================================

/// Switch the global VCS identity between personal and work.
pub fn switch(identity: SwitchIdentity) -> Result<(), AppError> {
    let ctx = identity_context()?;
    commands::switch::execute(&ctx, identity)
}

// =============================================================================
// Update
// =============================================================================

/// Check for and install updates to the mev CLI.
pub fn update() -> Result<(), AppError> {
    let source = InstallScriptVersionSource;
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
    let ctx = ansible_context()?;
    commands::backup::execute(&ctx, target)
}

fn ansible_context() -> Result<DependencyContainer, AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    DependencyContainer::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))
}

fn identity_context() -> Result<DependencyContainer, AppError> {
    DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))
}
