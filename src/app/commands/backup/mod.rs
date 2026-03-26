//! `backup` command orchestration — backup system settings or configurations.

mod system;
mod vscode;

use std::path::{Path, PathBuf};

use crate::app::DependencyContainer;
use crate::domain::backup_target::{BackupTarget, validate_backup_target};
use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;

enum DefinitionsDirResolution {
    Local(PathBuf),
    PackageDefault { resolved_dir: PathBuf, missing_local_dir: PathBuf },
}

/// Execute the `backup` command for a given target.
pub fn execute(ctx: &DependencyContainer, target_input: &str) -> Result<(), AppError> {
    let target = validate_backup_target(target_input)?;

    let local_config_dir = ctx.local_config_root.join(target.role()).join(target.subpath());

    println!("Running backup: {}", target.description());
    println!();

    match target {
        BackupTarget::System => {
            let definitions_dir = match resolve_definitions_dir(&local_config_dir, ctx, &target) {
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
            system::execute(ctx, &definitions_dir, &output_file)
        }
        BackupTarget::Vscode => {
            let output_file = local_config_dir.join("vscode-extensions.json");
            vscode::execute(ctx, &output_file)
        }
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
    ctx: &DependencyContainer,
    target: &BackupTarget,
) -> DefinitionsDirResolution {
    let local_definitions = local_config_dir.join("definitions");
    if local_definitions.exists() {
        return DefinitionsDirResolution::Local(local_definitions);
    }

    let package_default_dir = ctx
        .ansible
        .role_config_dir(target.role())
        .map(|p| p.join(target.subpath()).join("definitions"))
        .unwrap_or_default();

    DefinitionsDirResolution::PackageDefault {
        resolved_dir: package_default_dir,
        missing_local_dir: local_definitions,
    }
}

pub fn list_targets() {
    println!("Available backup targets:");
    println!();
    for target in BackupTarget::all() {
        println!("  {:<8} - {}", target.name(), target.description());
    }
    println!();
    println!("Usage: mev backup <target>");
}
