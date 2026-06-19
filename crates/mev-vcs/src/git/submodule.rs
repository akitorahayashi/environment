//! Git submodule deletion and path validation.

use std::path::{Component, Path};

use crate::error::VcsError;
use crate::git::client::Git;

/// Delete a git submodule completely from the current repository.
pub fn delete(submodule_path: &str) -> Result<(), VcsError> {
    validate_path(submodule_path)?;

    println!("Deleting submodule {submodule_path}...");
    let git = Git::default();
    git.delete_submodule_worktree(submodule_path)?;
    git.remove_submodule_module_dir(submodule_path)?;
    git.remove_submodule_config_section(submodule_path)?;
    println!("Submodule {submodule_path} deleted successfully.");
    Ok(())
}

/// Verify a string is a safe, relative path suitable for a submodule location.
/// Fails with `VcsError::InvalidSubmodulePath` if the path is empty, absolute,
/// or contains any non-normal component (for example `.` or `..`).
fn validate_path(path: &str) -> Result<(), VcsError> {
    let path = Path::new(path);

    let is_valid = !path.as_os_str().is_empty()
        && !path.is_absolute()
        && path.components().all(|component| matches!(component, Component::Normal(_)));

    if is_valid {
        return Ok(());
    }

    Err(VcsError::InvalidSubmodulePath(format!(
        "'{0}': must be a relative path without traversal",
        path.display()
    )))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::env_mock;
    use serial_test::serial;
    use std::fs;

    #[test]
    fn absolute_path_is_rejected() {
        assert!(validate_path("/absolute/path").is_err());
    }

    #[test]
    fn parent_traversal_is_rejected() {
        assert!(validate_path("../escape/path").is_err());
    }

    #[test]
    fn current_directory_is_rejected() {
        assert!(validate_path("./vendor/some-dep").is_err());
    }

    #[test]
    fn relative_path_is_accepted() {
        assert!(validate_path("vendor/some-dep").is_ok());
    }

    #[test]
    fn dotted_segment_is_accepted() {
        assert!(validate_path("vendor/some..dep").is_ok());
    }

    #[test]
    fn empty_path_is_rejected() {
        assert!(validate_path("").is_err());
    }

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
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };
        #[allow(unused_unsafe)]
        let _dir_guard = unsafe { env_mock::DirGuard::new(temp_dir.path())? };

        let modules_path = temp_dir.path().join(".git").join("modules").join("vendor/some-dep");
        fs::create_dir_all(&modules_path)?;

        delete("vendor/some-dep")?;

        let git_cmds = fs::read_to_string(git_args)?;
        assert!(git_cmds.contains("submodule deinit -f vendor/some-dep"));
        assert!(git_cmds.contains("rm -f -r vendor/some-dep"));
        assert!(git_cmds.contains("config --remove-section submodule.vendor/some-dep"));

        Ok(())
    }

    #[test]
    #[serial]
    fn fails_on_invalid_submodule_path() -> Result<(), Box<dyn std::error::Error>> {
        let err = delete("/absolute/path").unwrap_err();
        assert!(err.to_string().contains("invalid submodule path"));
        Ok(())
    }
}
