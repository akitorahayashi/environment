//! `backup` command orchestration — backup system settings or configurations.

use std::path::{Path, PathBuf};

use crate::app::AppContext;
use crate::backup;
use crate::backup::component::{BackupComponent, validate_backup_component};
use crate::error::AppError;
use crate::provisioning::role_configs::RoleConfigLocator;

enum DefinitionsDirResolution {
    Local(PathBuf),
    PackageDefault { resolved_dir: PathBuf, missing_local_dir: PathBuf },
}

/// Execute the `backup` command for a given component.
pub fn execute(ctx: &AppContext, component_input: &str) -> Result<(), AppError> {
    let component = validate_backup_component(component_input)?;

    let local_config_dir = ctx.local_config_root.join(component.role()).join(component.subpath());

    println!("Running backup: {}", component.description());
    println!();

    match component {
        BackupComponent::System => {
            let definitions_dir = match resolve_definitions_dir(&local_config_dir, ctx, &component)
            {
                DefinitionsDirResolution::Local(path) => path,
                DefinitionsDirResolution::PackageDefault { resolved_dir, missing_local_dir } => {
                    println!(
                        "Local definitions not found at {}. Using package defaults.",
                        missing_local_dir.display()
                    );
                    resolved_dir
                }
            };
            let output_file = local_config_dir.join("system.yml");
            backup::system::execute(ctx, &definitions_dir, &output_file)
        }
        BackupComponent::Vscode => backup::vscode::execute(ctx, &local_config_dir),
    }?;

    println!();
    println!("✓ Backup completed successfully!");

    Ok(())
}

// ---------------------------------------------------------------------------
// Directory resolution
// ---------------------------------------------------------------------------

/// Resolve definitions directory with fallback from local to package defaults.
fn resolve_definitions_dir(
    local_config_dir: &Path,
    ctx: &AppContext,
    component: &BackupComponent,
) -> DefinitionsDirResolution {
    let local_definitions = local_config_dir.join("definitions");
    if local_definitions.exists() {
        return DefinitionsDirResolution::Local(local_definitions);
    }

    let package_default_dir = ctx
        .provisioning
        .role_config_dir(component.role())
        .map(|p| p.join(component.subpath()).join("definitions"))
        .unwrap_or_default();

    DefinitionsDirResolution::PackageDefault {
        resolved_dir: package_default_dir,
        missing_local_dir: local_definitions,
    }
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
