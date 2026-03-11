//! CLI adapter — top-level parser and subcommand dispatch.

pub mod vcs;

use clap::{Parser, Subcommand};

#[derive(Parser)]
#[command(name = "mev-internal")]
#[command(version)]
#[command(about = "Internal command runtime for mev")]
struct Cli {
    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// VCS helpers.
    #[command(subcommand)]
    Vcs(vcs::VcsCommand),
}

/// Entry point for the CLI.
pub fn run() {
    let cli = Cli::parse();

    let result = match cli.command {
        Commands::Vcs(cmd) => vcs::run(cmd),
    };

    if let Err(err) = result {
        eprintln!("Error: {err}");
        std::process::exit(1);
    }
}
