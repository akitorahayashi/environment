//! CLI adapter — top-level parser and subcommand dispatch.

mod backup;
mod config;
mod create;
mod identity;
mod internal;
mod list;
mod make;
mod switch;
mod update;

use clap::{Parser, Subcommand};

use crate::error::AppError;

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
    #[command(visible_alias = "cr")]
    Create(create::CreateArgs),

    /// Run individual Ansible task by tag.
    #[command(visible_alias = "mk")]
    Make(make::MakeArgs),

    /// List available tags for make command.
    #[command(visible_alias = "ls")]
    List,

    /// Manage mev configuration.
    #[command(visible_alias = "cf", subcommand)]
    Config(config::ConfigCommand),

    /// Manage Git identity configuration.
    #[command(visible_alias = "id", subcommand)]
    Identity(identity::IdentityCommand),

    /// Switch Git identity between personal and work.
    #[command(visible_alias = "sw")]
    Switch(switch::SwitchArgs),

    /// Update mev.
    #[command(visible_alias = "u")]
    Update,

    /// Backup system settings or configurations.
    #[command(visible_alias = "bk")]
    Backup(backup::BackupArgs),

    /// Internal commands used by local aliases.
    #[command(subcommand, hide = true)]
    Internal(internal::InternalCommand),
}

/// Entry point for the CLI.
pub fn run() {
    let cli = Cli::parse();

    let result: Result<(), AppError> = match cli.command {
        Commands::Create(args) => create::run(args),
        Commands::Make(args) => make::run(args),
        Commands::List => list::run(),
        Commands::Config(cmd) => config::run(cmd),
        Commands::Identity(cmd) => identity::run(cmd),
        Commands::Switch(args) => switch::run(args),
        Commands::Update => update::run(),
        Commands::Backup(args) => backup::run(args),
        Commands::Internal(cmd) => internal::run(cmd),
    };

    if let Err(err) = result {
        eprintln!("Error: {err}");
        std::process::exit(1);
    }
}
