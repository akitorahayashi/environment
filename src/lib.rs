//! `mev` — macOS development environment provisioning CLI.
//!
//! Rust-first CLI owning command routing, validation, planning, and execution
//! orchestration. `mev-internal` is consumed as a relative dependency crate
//! for latency-sensitive internal command domains.

pub(crate) mod app;
pub mod backup;
pub mod cli;
pub mod error;
pub mod host_fs;
pub mod identity;
pub mod provisioning;
pub mod update;

#[cfg(test)]
pub(crate) mod test_support;

/// Entry point for the CLI.
pub use cli::run as cli;

use crate::app::AppContext;
use crate::error::AppError;
use crate::identity::model::IdentityScope;
use crate::provisioning::assets::locator;
use crate::provisioning::profile::Profile;
use crate::update::version_source::VersionSource;

/// Provision a complete development environment for the given profile.
pub fn create(profile: Profile, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ctx = provisioning_context()?;
    app::provisioning::create::execute(&ctx, profile, overwrite, verbose)
}

/// Run a single provisioning task by tag within a profile.
pub fn make(profile: Profile, tag: &str, overwrite: bool, verbose: bool) -> Result<(), AppError> {
    let ctx = provisioning_context()?;
    app::provisioning::make::execute(&ctx, profile, tag, overwrite, verbose)
}

/// Print the available tags, tag groups, and profiles.
pub fn list() -> Result<(), AppError> {
    let ctx = provisioning_context()?;
    app::provisioning::list::execute(&ctx)
}

/// Deploy role configuration files.
pub fn config_deploy(role: Option<String>, overwrite: bool) -> Result<(), AppError> {
    let ctx = provisioning_context()?;
    app::provisioning::deploy_role_configs::execute(&ctx, role, overwrite)
}

/// Show current Git identity configuration.
pub fn identity_show() -> Result<(), AppError> {
    let ctx = identity_context()?;
    app::identity::show::execute(&ctx)
}

/// Interactively set Git identity configuration.
pub fn identity_set() -> Result<(), AppError> {
    let ctx = identity_context()?;
    app::identity::set::execute(&ctx)
}

/// Switch the global Git identity between personal and work.
pub fn switch_identity(identity: IdentityScope) -> Result<(), AppError> {
    let ctx = identity_context()?;
    app::identity::switch::execute(&ctx, identity)
}

/// Check for and install updates to mev.
pub fn update() -> Result<(), AppError> {
    let source = update::install_script::InstallScriptVersionSource;
    app::update::run::execute(&source)
}

/// Update with a caller-supplied version source (test seam).
#[allow(dead_code)]
pub(crate) fn update_with_source(source: &dyn VersionSource) -> Result<(), AppError> {
    app::update::run::execute(source)
}

/// Backup a system setting or configuration component.
pub fn backup(component: &str) -> Result<(), AppError> {
    let ctx = provisioning_context()?;
    app::backup::run::execute(&ctx, component)
}

/// List available backup components.
pub fn backup_list() {
    app::backup::run::list_components();
}

fn provisioning_context() -> Result<AppContext, AppError> {
    let provisioning_assets = locator::locate_ansible_dir()?;
    AppContext::new(provisioning_assets).map_err(|e| AppError::Config(e.to_string()))
}

fn identity_context() -> Result<AppContext, AppError> {
    AppContext::for_identity().map_err(|e| AppError::Config(e.to_string()))
}
