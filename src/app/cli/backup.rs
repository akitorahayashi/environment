//! CLI input contract for the `backup` command.

use clap::Args;

use crate::adapters::ansible::locator;
use crate::app::AppContext;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Args)]
pub struct BackupArgs {
    /// Backup target (system, vscode) or 'list' to show available targets.
    pub target: String,
}

pub fn run(args: BackupArgs) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = AppContext::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;
    commands::backup::execute(&ctx, &args.target)
}
