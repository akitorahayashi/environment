//! GitHub CLI adapter.

use clap::Subcommand;

#[derive(Subcommand)]
pub enum GhCommand {
    /// GitHub label operations.
    #[command(subcommand)]
    Labels(GhLabelsCommand),
}

pub fn run(cmd: GhCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        GhCommand::Labels(cmd) => run_labels(cmd),
    }
}

#[derive(Subcommand)]
pub enum GhLabelsCommand {
    /// Delete all labels from the target repository.
    Reset(crate::app::commands::gh::labels_reset::LabelsResetArgs),

    /// Deploy the bundled label catalog to the target repository.
    Deploy(crate::app::commands::gh::labels_deploy::LabelsDeployArgs),
}

fn run_labels(cmd: GhLabelsCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        GhLabelsCommand::Reset(args) => crate::app::commands::gh::labels_reset::run(args),
        GhLabelsCommand::Deploy(args) => crate::app::commands::gh::labels_deploy::run(args),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn labels_subcommands_are_kebab_case() {
        let command = GhLabelsCommand::augment_subcommands(clap::Command::new("labels"));
        let names = command
            .get_subcommands()
            .map(|subcommand| subcommand.get_name().to_owned())
            .collect::<Vec<_>>();

        assert!(names.iter().any(|name| name == "reset"));
        assert!(names.iter().any(|name| name == "deploy"));
    }
}
