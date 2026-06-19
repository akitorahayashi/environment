//! Clone one or more repositories sequentially.

use crate::error::VcsError;
use crate::git::client::Git;

/// Clone each repository URL in order, stopping at the first failure.
///
/// Tokens before a `--` separator are repository URLs; tokens after it are
/// `git clone` flags applied to every clone (e.g. `urlA urlB -- --depth 1`).
/// URL scheme (https/ssh) is handled by git itself.
pub fn clone(tokens: &[String]) -> Result<(), VcsError> {
    let (urls, flags) = split_urls_and_flags(tokens);

    let git = Git::default();
    for url in urls {
        println!("Cloning {url}...");
        git.clone(flags, url)?;
    }
    Ok(())
}

fn split_urls_and_flags(tokens: &[String]) -> (&[String], &[String]) {
    match tokens.iter().position(|token| token == "--") {
        Some(separator) => (&tokens[..separator], &tokens[separator + 1..]),
        None => (tokens, &[]),
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
    fn clones_each_url_in_order() -> Result<(), Box<dyn std::error::Error>> {
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

        clone(&[
            "https://github.com/owner/first.git".to_string(),
            "git@github.com:owner/second.git".to_string(),
        ])?;

        let git_cmds = fs::read_to_string(args_file)?;
        let mut lines = git_cmds.lines();
        assert_eq!(
            lines.next().ok_or("missing first clone")?.trim(),
            "clone https://github.com/owner/first.git"
        );
        assert_eq!(
            lines.next().ok_or("missing second clone")?.trim(),
            "clone git@github.com:owner/second.git"
        );
        Ok(())
    }

    #[test]
    #[serial]
    fn stops_at_first_failure() -> Result<(), Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let args_file = temp_dir.path().join("git_args.txt");
        // Mock fails on the first invocation, so the second URL is never reached.
        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                exit 1
            "#,
                args_file.display()
            ),
        )?;

        #[allow(unused_unsafe)]
        let _guard = unsafe { env_mock::PathGuard::new(&bin_path)? };

        let result = clone(&[
            "https://github.com/owner/first.git".to_string(),
            "git@github.com:owner/second.git".to_string(),
        ]);

        assert!(result.is_err());

        let git_cmds = fs::read_to_string(args_file)?;
        assert_eq!(git_cmds.lines().count(), 1, "should stop after the first failed clone");
        assert!(git_cmds.contains("clone https://github.com/owner/first.git"));
        assert!(!git_cmds.contains("second"));
        Ok(())
    }

    #[test]
    #[serial]
    fn applies_flags_after_separator_to_every_clone() -> Result<(), Box<dyn std::error::Error>> {
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

        clone(&[
            "https://github.com/owner/first.git".to_string(),
            "git@github.com:owner/second.git".to_string(),
            "--".to_string(),
            "--depth".to_string(),
            "1".to_string(),
        ])?;

        let git_cmds = fs::read_to_string(args_file)?;
        let mut lines = git_cmds.lines();
        assert_eq!(
            lines.next().ok_or("missing first clone")?.trim(),
            "clone --depth 1 https://github.com/owner/first.git"
        );
        assert_eq!(
            lines.next().ok_or("missing second clone")?.trim(),
            "clone --depth 1 git@github.com:owner/second.git"
        );
        Ok(())
    }
}
