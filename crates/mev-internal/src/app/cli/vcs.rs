//! VCS helpers.

use std::process::Command;

use clap::Subcommand;

#[derive(Subcommand)]
pub enum VcsCommand {
    /// Delete a git submodule completely.
    DeleteSubmodule {
        /// Relative path to the submodule.
        submodule_path: String,
    },
}

pub fn run(cmd: VcsCommand) -> Result<(), Box<dyn std::error::Error>> {
    match cmd {
        VcsCommand::DeleteSubmodule { submodule_path } => delete_submodule(&submodule_path),
    }
}

fn is_valid_submodule_path(path: &str) -> bool {
    !path.starts_with('/') && !path.contains("..")
}

fn delete_submodule(submodule_path: &str) -> Result<(), Box<dyn std::error::Error>> {
    if !is_valid_submodule_path(submodule_path) {
        eprintln!(
            "Error: Invalid submodule path '{submodule_path}'. \
             Must be a relative path without '..'."
        );
        std::process::exit(1);
    }

    println!("Deleting submodule {submodule_path}...");

    let steps: &[(&[&str], bool)] = &[
        (&["git", "submodule", "deinit", "-f", submodule_path], true),
        (&["git", "rm", "-f", "-r", submodule_path], true),
        (&["rm", "-rf", &format!(".git/modules/{submodule_path}")], true),
    ];

    for (args, required) in steps {
        let status = Command::new(args[0]).args(&args[1..]).status();
        match status {
            Ok(s) if s.success() => {}
            Ok(s) if *required => {
                eprintln!("Error: {} exited with code {}", args.join(" "), s.code().unwrap_or(1));
                std::process::exit(1);
            }
            Err(e) if *required => {
                eprintln!("Error: {e}");
                std::process::exit(1);
            }
            _ => {}
        }
    }

    // Attempt to remove config section (non-fatal "No such section")
    let config_result = Command::new("git")
        .args(["config", "--remove-section", &format!("submodule.{submodule_path}")])
        .output();

    if let Ok(output) = config_result
        && !output.status.success()
    {
        let stderr = String::from_utf8_lossy(&output.stderr);
        if !stderr.contains("No such section") {
            eprintln!("Warning: Could not remove config section: {}", stderr.trim());
        }
    }

    println!("✅ Submodule {submodule_path} deleted successfully.");
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn absolute_path_is_rejected() {
        assert!(!is_valid_submodule_path("/absolute/path"));
    }

    #[test]
    fn parent_traversal_is_rejected() {
        assert!(!is_valid_submodule_path("../escape/path"));
    }

    #[test]
    fn relative_path_is_accepted() {
        assert!(is_valid_submodule_path("vendor/some-dep"));
    }
}
