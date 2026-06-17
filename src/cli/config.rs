//! CLI input contract for the `config` command.

use clap::{Subcommand, ValueEnum};

use crate::coder::Selectable;
use crate::error::AppError;

#[derive(Subcommand)]
pub enum ConfigCommand {
    /// Deploy role configs to ~/.config/mev/roles/.
    #[command(visible_alias = "dp")]
    Deploy {
        /// Role name to deploy config for. If omitted, deploys all roles.
        role: Option<String>,

        /// Overwrite existing config with package defaults.
        #[arg(short, long)]
        overwrite: bool,
    },

    /// Interactively select enabled AGENTS.md sections or skills.
    #[command(visible_alias = "sl")]
    Select {
        /// What to select: agents (AGENTS.md sections) or skills.
        #[arg(value_enum)]
        object: SelectObject,

        /// Disable all entries (produces an empty AGENTS.md or skills directory).
        #[arg(short, long)]
        clear: bool,
    },
}

#[derive(Clone, Copy, ValueEnum)]
pub enum SelectObject {
    /// AGENTS.md sections.
    #[value(alias = "ag")]
    Agents,
    /// Deployable skills.
    #[value(alias = "sk")]
    Skills,
}

impl From<SelectObject> for Selectable {
    fn from(object: SelectObject) -> Self {
        match object {
            SelectObject::Agents => Selectable::Agents,
            SelectObject::Skills => Selectable::Skills,
        }
    }
}

pub fn run(cmd: ConfigCommand) -> Result<(), AppError> {
    match cmd {
        ConfigCommand::Deploy { role, overwrite } => crate::config_deploy(role, overwrite),
        ConfigCommand::Select { object, clear: true } => crate::config_select_clear(object.into()),
        ConfigCommand::Select { object, clear: false } => crate::config_select(object.into()),
    }
}
