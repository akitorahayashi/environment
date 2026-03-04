//! CLI adapter — top-level parser and subcommand dispatch.

pub mod aider;
pub mod shell;
pub mod ssh;
pub mod vcs;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "menv-internal")]
#[command(version)]
#[command(about = "Internal command runtime for menv")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Aider integration helpers.
    #[command(subcommand)]
    Aider(aider::AiderCommand),

    /// Shell helper generators.
    #[command(subcommand)]
    Shell(shell::ShellCommand),

    /// SSH key and host configuration.
    #[command(subcommand)]
    Ssh(ssh::SshCommand),

    /// VCS helpers.
    #[command(subcommand)]
    Vcs(vcs::VcsCommand),
}

/// Entry point for the CLI.
pub fn run() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Aider(cmd) => aider::run(cmd),
        Commands::Shell(cmd) => shell::run(cmd),
        Commands::Ssh(cmd) => ssh::run(cmd),
        Commands::Vcs(cmd) => vcs::run(cmd),
    };

    if let Err(err) = result {
        eprintln!("Error: {err}");
        std::process::exit(1);
    }
}
