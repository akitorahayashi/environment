//! CLI adapter — top-level parser and subcommand dispatch.

mod backup;
mod config;
mod create;
mod list;
mod make;
mod switch;
mod update;

use clap::{Parser, Subcommand};

use crate::domain::error::AppError;

#[derive(Parser)]
#[command(name = "mev")]
#[command(version)]
#[command(about = "macOS development environment provisioning CLI")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Create a complete development environment for a profile.
    #[command(alias = "cr")]
    Create(create::CreateArgs),

    /// Run individual Ansible task by tag.
    #[command(alias = "mk")]
    Make(make::MakeArgs),

    /// List available tags for make command.
    #[command(alias = "ls")]
    List,

    /// Manage mev configuration.
    #[command(alias = "cf", subcommand)]
    Config(config::ConfigCommand),

    /// Switch VCS identity between personal and work.
    #[command(alias = "sw")]
    Switch(switch::SwitchArgs),

    /// Update mev.
    #[command(alias = "u")]
    Update,

    /// Backup system settings or configurations.
    #[command(alias = "bk")]
    Backup(backup::BackupArgs),

    /// Internal commands used by shell aliases.
    #[command(subcommand, hide = true)]
    Internal(InternalCommand),
}

/// Internal subcommands delegated to `mev-internal`.
#[derive(Subcommand)]
enum InternalCommand {
    /// Aider integration helpers.
    #[command(subcommand)]
    Aider(mev_internal::app::cli::aider::AiderCommand),

    /// Shell helper generators.
    #[command(subcommand)]
    Shell(mev_internal::app::cli::shell::ShellCommand),

    /// SSH key and host configuration.
    #[command(subcommand)]
    Ssh(mev_internal::app::cli::ssh::SshCommand),

    /// VCS helpers.
    #[command(subcommand)]
    Vcs(mev_internal::app::cli::vcs::VcsCommand),
}

/// Entry point for the CLI.
pub fn run() {
    let cli = Cli::parse();

    let result: Result<(), AppError> = match cli.command {
        Commands::Create(args) => create::run(args),
        Commands::Make(args) => make::run(args),
        Commands::List => list::run(),
        Commands::Config(cmd) => config::run(cmd),
        Commands::Switch(args) => switch::run(args),
        Commands::Update => update::run(),
        Commands::Backup(args) => backup::run(args),
        Commands::Internal(cmd) => run_internal(cmd),
    };

    if let Err(err) = result {
        eprintln!("Error: {err}");
        std::process::exit(1);
    }
}

fn run_internal(cmd: InternalCommand) -> Result<(), AppError> {
    let result = match cmd {
        InternalCommand::Aider(c) => mev_internal::app::cli::aider::run(c),
        InternalCommand::Shell(c) => mev_internal::app::cli::shell::run(c),
        InternalCommand::Ssh(c) => mev_internal::app::cli::ssh::run(c),
        InternalCommand::Vcs(c) => mev_internal::app::cli::vcs::run(c),
    };
    result.map_err(|e| AppError::Config(e.to_string()))
}
