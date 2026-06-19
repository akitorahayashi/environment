//! Deploy and reset GitHub labels on a target repository.

use crate::error::VcsError;
use crate::gh::catalog;
use crate::gh::client::Gh;
use crate::git::client::Git;
use crate::git::repo_ref;

/// Deploy the bundled label catalog to the target repository.
pub fn deploy(repo: Option<&str>) -> Result<(), VcsError> {
    let target = resolve_target(repo)?;

    let gh = Gh::default();
    let existing_names = gh.list_label_names(&target)?;
    let label_specs = catalog::load_bundled_labels()?;

    for spec in label_specs {
        if existing_names.iter().any(|name| name == &spec.name) {
            println!("Replacing label {} in {}...", spec.name, target.as_gh_repo_arg());
            gh.delete_label(&target, &spec.name)?;
        } else {
            println!("Creating label {} in {}...", spec.name, target.as_gh_repo_arg());
        }

        gh.create_label(&target, &spec)?;
    }

    println!("Deployed bundled labels to {}.", target.as_gh_repo_arg());
    Ok(())
}

/// Delete all labels from the target repository.
pub fn reset(repo: Option<&str>) -> Result<(), VcsError> {
    let target = resolve_target(repo)?;

    let gh = Gh::default();
    let names = gh.list_label_names(&target)?;

    if names.is_empty() {
        println!("No labels to delete in {}.", target.as_gh_repo_arg());
        return Ok(());
    }

    for name in names {
        println!("Deleting label {name} from {}...", target.as_gh_repo_arg());
        gh.delete_label(&target, &name)?;
    }

    println!("Deleted all labels from {}.", target.as_gh_repo_arg());
    Ok(())
}

fn resolve_target(repo: Option<&str>) -> Result<repo_ref::RepositoryRef, VcsError> {
    let origin_url = repo.is_none().then(|| Git::default().current_origin_url()).transpose()?;
    repo_ref::resolve(repo, origin_url.as_deref())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing::env_mock;
    use serial_test::serial;
    use std::fs;
    use std::path::Path;

    struct TestEnvironment {
        temp_dir: tempfile::TempDir,
        gh_args_path: std::path::PathBuf,
        _path_guard: env_mock::PathGuard,
    }

    fn setup() -> Result<TestEnvironment, Box<dyn std::error::Error>> {
        let temp_dir = tempfile::tempdir()?;
        let git_args_path = temp_dir.path().join("git_args.txt");
        let gh_args_path = temp_dir.path().join("gh_args.txt");

        let bin_path = env_mock::create_mock_bin(
            "git",
            &temp_dir,
            &git_origin_capture_script(&git_args_path),
        )?;

        Ok(TestEnvironment {
            temp_dir,
            gh_args_path,
            _path_guard: env_mock::PathGuard::new(&bin_path)?,
        })
    }

    fn git_origin_capture_script(git_args_path: &Path) -> String {
        format!(
            r#"#!/bin/sh
		echo "$@" >> "{}"
		echo "git@github.com:owner/repo.git"
	"#,
            git_args_path.display()
        )
    }

    #[test]
    #[serial]
    fn deploys_labels_successfully_without_replacements() -> Result<(), Box<dyn std::error::Error>>
    {
        let test_env = setup()?;
        env_mock::create_mock_bin(
            "gh",
            &test_env.temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo ""
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        )?;

        deploy(None)?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(gh_cmds.contains("label create C-bugs"));
        assert!(!gh_cmds.contains("label delete"));

        Ok(())
    }

    #[test]
    #[serial]
    fn deploys_labels_with_replacements() -> Result<(), Box<dyn std::error::Error>> {
        let test_env = setup()?;
        env_mock::create_mock_bin(
            "gh",
            &test_env.temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo "C-bugs"
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        )?;

        deploy(Some("owner/repo"))?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(gh_cmds.contains("label delete C-bugs"));
        assert!(gh_cmds.contains("label create C-bugs"));

        Ok(())
    }

    #[test]
    #[serial]
    fn resets_all_labels_successfully() -> Result<(), Box<dyn std::error::Error>> {
        let test_env = setup()?;
        env_mock::create_mock_bin(
            "gh",
            &test_env.temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo "bugs\nfeats"
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        )?;

        reset(None)?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(gh_cmds.contains("label delete bugs"));
        assert!(gh_cmds.contains("label delete feats"));

        Ok(())
    }

    #[test]
    #[serial]
    fn skips_reset_if_no_labels() -> Result<(), Box<dyn std::error::Error>> {
        let test_env = setup()?;
        env_mock::create_mock_bin(
            "gh",
            &test_env.temp_dir,
            &format!(
                r#"#!/bin/sh
                echo "$@" >> "{}"
                if [ "$1" = "label" ] && [ "$2" = "list" ]; then
                    echo ""
                else
                    exit 0
                fi
            "#,
                test_env.gh_args_path.display()
            ),
        )?;

        reset(Some("owner/repo"))?;

        let gh_cmds = fs::read_to_string(&test_env.gh_args_path)?;
        assert!(!gh_cmds.contains("label delete"));

        Ok(())
    }
}
