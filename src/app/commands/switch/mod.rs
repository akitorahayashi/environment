//! `switch` command orchestration — VCS identity switching.

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::git::GitPort;
use crate::domain::ports::identity_store::IdentityStore;
use crate::domain::ports::jj::JjPort;
use crate::domain::vcs_identity;

/// Execute the `switch` command: change global git/jj identity.
pub fn execute(ctx: &DependencyContainer, identity_input: &str) -> Result<(), AppError> {
    if !ctx.identity_store.exists() {
        eprintln!("No identity configuration found.");
        eprintln!("Run 'mev identity set' first to configure identities.");
        return Err(AppError::Config("no identity configuration found".to_string()));
    }

    let resolved = vcs_identity::resolve_switch_identity(identity_input).ok_or_else(|| {
        AppError::InvalidIdentity(format!(
            "invalid identity '{identity_input}'. Valid: personal (p), work (w)"
        ))
    })?;

    let identity = ctx
        .identity_store
        .get_identity(resolved)?
        .ok_or_else(|| AppError::Config(format!("failed to load {resolved} identity")))?;

    if identity.name.is_empty() || identity.email.is_empty() {
        return Err(AppError::Config(format!(
            "{resolved} identity is not configured. Run 'mev identity set' to configure."
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
