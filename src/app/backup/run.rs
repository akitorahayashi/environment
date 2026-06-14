//! `backup` command orchestration — backup system settings or configurations.

use crate::app::AppContext;
use crate::backup;
use crate::backup::component::{BackupComponent, validate_backup_component};
use crate::error::AppError;

/// Execute the `backup` command for a given component.
pub fn execute(ctx: &AppContext, component_input: &str) -> Result<(), AppError> {
    let component = validate_backup_component(component_input)?;

    let local_config_dir = ctx.local_config_root.join(component.role()).join(component.subpath());

    println!("Running backup: {}", component.description());
    println!();

    match component {
        BackupComponent::System => {
            let package_definitions =
                ctx.provisioning_asset_root().join("roles/system/config/global");
            let local_definitions = local_config_dir;
            backup::system::execute(ctx, &package_definitions, &local_definitions)
        }
        BackupComponent::Vscode | BackupComponent::AntigravityIde => {
            backup::code_editors::execute(ctx, component, &local_config_dir)
        }
    }?;

    println!();
    println!("✓ Backup completed successfully!");

    Ok(())
}

pub fn list_components() {
    println!("Available backup components:");
    println!();
    for component in BackupComponent::all() {
        println!("  {:<8} - {}", component.name(), component.description());
    }
    println!();
    println!("Usage: mev backup <component>");
}
