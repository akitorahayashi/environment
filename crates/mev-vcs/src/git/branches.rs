//! Local branch deletion workflow.

use crate::error::VcsError;
use crate::git::client::Git;

const DEFAULT_CHECKOUT_BRANCH: &str = "main";

/// Update the checkout branch, delete the requested local branches, and prune stale origin refs.
///
/// Tokens before a `--` separator are local branch names to delete. When a
/// separator is present, the single token after it is the branch to checkout
/// before deletion. Without a separator, `main` is used.
pub fn delete(tokens: &[String]) -> Result<(), VcsError> {
    let request = DeleteBranchesRequest::parse(tokens)?;
    let git = Git::default();
    git.checkout_branch(request.checkout_branch)?;
    git.pull()?;
    git.delete_branches(request.delete_branches)?;
    git.prune_origin()?;
    Ok(())
}

struct DeleteBranchesRequest<'a> {
    delete_branches: &'a [String],
    checkout_branch: &'a str,
}

impl<'a> DeleteBranchesRequest<'a> {
    fn parse(tokens: &'a [String]) -> Result<Self, VcsError> {
        match tokens.iter().position(|token| token == "--") {
            Some(separator) => Self::parse_with_checkout_branch(tokens, separator),
            None => Self::parse_default_checkout_branch(tokens),
        }
    }

    fn parse_with_checkout_branch(
        tokens: &'a [String],
        separator: usize,
    ) -> Result<Self, VcsError> {
        let delete_branches = &tokens[..separator];
        let checkout_branches = &tokens[separator + 1..];

        if delete_branches.is_empty() {
            return Err(VcsError::InvalidBranchDeletionArgs(
                "at least one branch to delete is required before `--`".to_string(),
            ));
        }

        match checkout_branches {
            [checkout_branch] => Ok(Self { delete_branches, checkout_branch }),
            [] => Err(VcsError::InvalidBranchDeletionArgs(
                "checkout branch is required after `--`".to_string(),
            )),
            _ => Err(VcsError::InvalidBranchDeletionArgs(
                "only one checkout branch is allowed after `--`".to_string(),
            )),
        }
    }

    fn parse_default_checkout_branch(tokens: &'a [String]) -> Result<Self, VcsError> {
        if tokens.is_empty() {
            return Err(VcsError::InvalidBranchDeletionArgs(
                "at least one branch to delete is required".to_string(),
            ));
        }

        Ok(Self { delete_branches: tokens, checkout_branch: DEFAULT_CHECKOUT_BRANCH })
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::env_mock;
    use serial_test::serial;
    use std::fs;

    #[test]
    #[serial]
    fn updates_main_deletes_branches_and_prunes_origin() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("git_args.txt");
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                exit 0
            "#,
                args_file.display()
            ),
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };

        delete(&["feature/a".to_string(), "feature/b".to_string()])?;

        let git_cmds = fs::read_to_string(args_file)?;
        let lines = git_cmds.lines().map(str::trim).collect::<Vec<_>>();
        assert_eq!(
            lines,
            ["checkout main", "pull", "branch -D -- feature/a feature/b", "remote prune origin",]
        );
        Ok(())
    }

    #[test]
    #[serial]
    fn updates_requested_branch_before_deleting_branches() -> Result<(), Box<dyn std::error::Error>>
    {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("git_args.txt");
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                exit 0
            "#,
                args_file.display()
            ),
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };

        delete(&["feature/a".to_string(), "--".to_string(), "develop".to_string()])?;

        let git_cmds = fs::read_to_string(args_file)?;
        let lines = git_cmds.lines().map(str::trim).collect::<Vec<_>>();
        assert_eq!(
            lines,
            ["checkout develop", "pull", "branch -D -- feature/a", "remote prune origin",]
        );
        Ok(())
    }

    #[test]
    #[serial]
    fn fails_before_git_commands_when_checkout_branch_is_missing()
    -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("git_args.txt");
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                exit 0
            "#,
                args_file.display()
            ),
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };

        let result = delete(&["feature/a".to_string(), "--".to_string()]);

        assert!(result.is_err());
        assert!(!args_file.exists());
        Ok(())
    }

    #[test]
    #[serial]
    fn stops_before_delete_when_pull_fails() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("git_args.txt");
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "pull" ]; then
                    exit 1
                fi
                exit 0
            "#,
                args_file.display()
            ),
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };

        let result = delete(&["feature/a".to_string()]);

        assert!(result.is_err());
        let git_cmds = fs::read_to_string(args_file)?;
        let lines = git_cmds.lines().map(str::trim).collect::<Vec<_>>();
        assert_eq!(lines, ["checkout main", "pull"]);
        Ok(())
    }
}
