//! `switch` command orchestration — VCS identity switching.

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::git::GitPort;
use crate::domain::ports::identity_store::IdentityStore;
use crate::domain::ports::jj::JjPort;
use crate::domain::vcs_identity::SwitchIdentity;

/// Execute the `switch` command: change global git/jj identity.
pub fn execute(ctx: &DependencyContainer, identity: SwitchIdentity) -> Result<(), AppError> {
    if !ctx.identity_store.exists() {
        eprintln!("No identity configuration found.");
        eprintln!("Run 'mev identity set' first to configure identities.");
        return Err(AppError::Config("no identity configuration found".to_string()));
    }

    let vcs_identity = ctx
        .identity_store
        .get_identity(identity)?
        .ok_or_else(|| AppError::Config(format!("failed to load {} identity", identity)))?;

    if vcs_identity.name.is_empty() || vcs_identity.email.is_empty() {
        return Err(AppError::Config(format!(
            "{identity} identity is not configured. Run 'mev identity set' to configure."
        )));
    }

    println!("Switching to {} identity...", identity);

    // Git configuration (required)
    ctx.git.set_identity(&vcs_identity.name, &vcs_identity.email)?;

    // Jujutsu configuration (optional — skip if jj not installed)
    if ctx.jj.is_available()
        && let Err(e) = ctx.jj.set_identity(&vcs_identity.name, &vcs_identity.email)
    {
        eprintln!("Warning: jj identity update failed: {e}");
    }

    // Show current configuration via git (primary VCS)
    let (name, email) = ctx.git.get_identity()?;
    println!();
    println!("Switched to {} identity", identity);
    println!("  Name:  {name}");
    println!("  Email: {email}");

    Ok(())
}
