//! `switch` command orchestration — Git identity switching.

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::identity::IdentityScope;
use crate::domain::ports::git::GitPort;
use crate::domain::ports::identity_store::IdentityStore;

/// Execute the `switch` command: change global Git identity.
pub fn execute(ctx: &DependencyContainer, identity: IdentityScope) -> Result<(), AppError> {
    if !ctx.identity_store.exists() {
        eprintln!("No identity configuration found.");
        eprintln!("Run 'mev identity set' first to configure identities.");
        return Err(AppError::Config("no identity configuration found".to_string()));
    }

    let identity_config = ctx
        .identity_store
        .get_identity(identity)?
        .ok_or_else(|| AppError::Config(format!("failed to load {} identity", identity)))?;

    if !identity_config.is_configured() {
        return Err(AppError::Config(format!(
            "{identity} identity is not configured. Run 'mev identity set' to configure."
        )));
    }

    println!("Switching to {} identity...", identity);

    // Git configuration (required)
    ctx.git.set_identity(&identity_config.name, &identity_config.email)?;

    // Show current configuration via git.
    let (name, email) = ctx.git.get_identity()?;
    println!();
    println!("Switched to {} identity", identity);
    println!("  Name:  {name}");
    println!("  Email: {email}");

    Ok(())
}
