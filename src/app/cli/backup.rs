//! CLI input contract for the `backup` command.

use clap::Args;

use crate::adapters::ansible::locator;
use crate::app::DependencyContainer;
use crate::app::commands;
use crate::domain::error::AppError;

#[derive(Args)]
pub struct BackupArgs {
    #[arg(short = 'l', long = "list", aliases = ["ls"], action = clap::ArgAction::SetTrue, help = "List available backup targets")]
    pub list: bool,

    /// Backup target (system, vscode).
    pub target: Option<String>,
}

pub fn run(args: BackupArgs) -> Result<(), AppError> {
    let ansible_dir = locator::locate_ansible_dir()?;
    let ctx = DependencyContainer::new(ansible_dir).map_err(|e| AppError::Config(e.to_string()))?;

    if args.list {
        commands::backup::list_targets();
        Ok(())
    } else if let Some(target) = args.target {
        commands::backup::execute(&ctx, &target)
    } else {
        Err(AppError::Backup("Target is required unless --list is used.".to_string()))
    }
}
