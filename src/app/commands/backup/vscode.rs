//! VSCode extensions backup implementation.

use std::path::Path;

use crate::app::DependencyContainer;
use crate::domain::error::AppError;
use crate::domain::ports::fs::FsPort;
use crate::domain::ports::vscode::VscodePort;

pub fn execute(ctx: &DependencyContainer, output_file: &Path) -> Result<(), AppError> {
    let mut extensions = ctx.vscode.list_extensions()?;
    extensions.sort();
    extensions.dedup();

    let payload = serde_json::json!({ "extensions": extensions });
    let content = serde_json::to_string_pretty(&payload)
        .map_err(|e| AppError::Backup(format!("failed to serialize extensions: {e}")))?;

    if let Some(parent) = output_file.parent() {
        ctx.fs.create_dir_all(parent)?;
    }
    ctx.fs.write(output_file, format!("{content}\n").as_bytes())?;

    println!("VSCode extensions list backed up to: {}", output_file.display());
    Ok(())
}
