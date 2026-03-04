//! `switch` command orchestration — VCS identity switching.

use crate::app::AppContext;
use crate::domain::config;
use crate::domain::error::AppError;
use crate::domain::ports::config_store::ConfigStore;
use crate::domain::ports::git::GitPort;
use crate::domain::ports::jj::JjPort;

/// Execute the `switch` command: change global git/jj identity.
pub fn execute(ctx: &AppContext, profile_input: &str) -> Result<(), AppError> {
    if !ctx.config_store.exists() {
        eprintln!("No configuration found.");
        eprintln!("Run 'mev config set' first to configure identities.");
        return Err(AppError::Config("no configuration found".to_string()));
    }

    let resolved = config::resolve_switch_profile(profile_input).ok_or_else(|| {
        AppError::InvalidProfile(format!(
            "invalid profile '{profile_input}'. Valid: personal (p), work (w)"
        ))
    })?;

    let identity = ctx
        .config_store
        .get_identity(resolved)?
        .ok_or_else(|| AppError::Config(format!("failed to load {resolved} identity")))?;

    if identity.name.is_empty() || identity.email.is_empty() {
        return Err(AppError::Config(format!(
            "{resolved} identity is not configured. Run 'mev config set' to configure."
        )));
    }

    println!("Switching to {resolved} identity...");

    // Git configuration (required)
    ctx.git.set_identity(&identity.name, &identity.email)?;

    // Jujutsu configuration (optional — skip if jj not installed)
    if ctx.jj.is_available()
        && let Err(e) = ctx.jj.set_identity(&identity.name, &identity.email)
    {
        eprintln!("Warning: jj identity update failed: {e}");
    }

    // Show current configuration via git (primary VCS)
    let (name, email) = ctx.git.get_identity()?;
    println!();
    println!("Switched to {resolved} identity");
    println!("  Name:  {name}");
    println!("  Email: {email}");

    Ok(())
}
