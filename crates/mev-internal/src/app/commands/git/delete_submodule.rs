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
    let git_adapter = git::GitAdapter::default();
    git_adapter.delete_submodule_worktree(&args.submodule_path)?;
    git_adapter.remove_submodule_module_dir(&args.submodule_path)?;
    git_adapter.remove_submodule_config_section(&args.submodule_path)?;
    println!("Submodule {} deleted successfully.", args.submodule_path);
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::env_mock;
    use serial_test::serial;
    use std::fs;

    #[test]
    #[serial]
    fn deletes_submodule_successfully() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let git_args = temp_dir.path().join("git_args.txt");

        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                exit 0
            "#,
                git_args.display()
            ),
        );

        let _guard = env_mock::PathGuard::new(&bin_path);
        let _dir_guard = env_mock::DirGuard::new(temp_dir.path());

        let modules_path = temp_dir.path().join(".git").join("modules").join("vendor/some-dep");
        fs::create_dir_all(&modules_path)?;

        run(DeleteSubmoduleArgs { submodule_path: "vendor/some-dep".to_string() })?;

        let git_cmds = fs::read_to_string(git_args)?;
        assert!(git_cmds.contains("submodule deinit -f vendor/some-dep"));
        assert!(git_cmds.contains("rm -f -r vendor/some-dep"));
        assert!(git_cmds.contains("config --remove-section submodule.vendor/some-dep"));

        Ok(())
    }

    #[test]
    fn fails_on_invalid_submodule_path() -> Result<(), Box<dyn std::error::Error>> {
        let err =
            run(DeleteSubmoduleArgs { submodule_path: "/absolute/path".to_string() }).unwrap_err();
        assert!(err.to_string().contains("invalid submodule path"));
        Ok(())
    }
}
