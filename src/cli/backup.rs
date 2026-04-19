//! CLI input contract for the `backup` command.

use clap::Args;

use crate::error::AppError;

#[derive(Args)]
#[command(group(
    clap::ArgGroup::new("action")
        .required(true)
        .args(["list", "target"]),
))]
pub struct BackupArgs {
    #[arg(short = 'l', long = "list", aliases = ["ls"], action = clap::ArgAction::SetTrue, help = "List available backup components")]
    pub list: bool,

    /// Backup component (system, vscode).
    #[arg(name = "target", value_name = "COMPONENT")]
    pub component: Option<String>,
}

pub fn run(args: BackupArgs) -> Result<(), AppError> {
    if args.list {
        crate::backup_list();
        Ok(())
    } else if let Some(component) = args.component {
        crate::backup(component.as_str())
    } else {
        // Controlled by ArgGroup(required=true)
        unreachable!("clap ensures either list or component is present")
    }
}
