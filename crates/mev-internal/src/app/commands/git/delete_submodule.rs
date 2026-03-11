//! Delete a git submodule from the current repository.

use clap::Args;

use crate::adapters::git;
use crate::domain::submodule_path;

#[derive(Args)]
pub struct DeleteSubmoduleArgs {
    /// Relative path to the submodule.
    pub submodule_path: String,
}

pub fn run(args: DeleteSubmoduleArgs) -> Result<(), Box<dyn std::error::Error>> {
    submodule_path::validate_submodule_path(&args.submodule_path)?;

    println!("Deleting submodule {}...", args.submodule_path);
    git::delete_submodule_worktree(&args.submodule_path)?;
    git::remove_submodule_module_dir(&args.submodule_path)?;
    git::remove_submodule_config_section(&args.submodule_path)?;
    println!("Submodule {} deleted successfully.", args.submodule_path);
    Ok(())
}
