//! Internal entrypoints for command execution.
//!
//! Each function wires context creation to command execution.
//! `cli/` modules and other crate-level callers delegate here to ensure
//! consistent execution logic.

use crate::adapters::ansible::locator;
use crate::adapters::version_source::install_script::InstallScriptVersionSource;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;
use crate::domain::identity::IdentityScope;
use crate::domain::ports::version_source::VersionSource;
use crate::domain::profile::Profile;

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
pub fn config_deploy(role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::config::deploy(&ctx, role, overwrite)
}

// =============================================================================
// Identity
// =============================================================================

/// Show current Git identity configuration.
pub fn identity_show() -> Result<(), AppError> {
    let ctx = identity_context()?;
    commands::identity::show(&ctx)
}

/// Interactively set Git identity configuration.
pub fn identity_set() -> Result<(), AppError> {
    let ctx = identity_context()?;
    commands::identity::set(&ctx)
}

// =============================================================================
// Switch
// =============================================================================

/// Switch the global Git identity between personal and work.
pub fn switch(identity: IdentityScope) -> Result<(), AppError> {
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

/// Backup a system setting or configuration component.
pub fn backup(component: &str) -> Result<(), AppError> {
    let ctx = ansible_context()?;
    commands::backup::execute(&ctx, component)
}

/// List available backup components.
pub fn backup_list() {
    commands::backup::list_components();
}

fn ansible_context() -> Result<DependencyContainer, AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    DependencyContainer::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))
}

fn identity_context() -> Result<DependencyContainer, AppError> {
    DependencyContainer::for_identity().map_err(|e| AppError::Config(e.to_string()))
}
