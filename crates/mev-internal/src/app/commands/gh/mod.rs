//! GitHub CLI command orchestration.

pub mod labels_deploy;
pub mod labels_reset;

#[cfg(test)]
use crate::testing::env_mock;
#[cfg(test)]
use std::path::Path;

#[cfg(test)]
pub(crate) struct GhLabelsCommandTestEnvironment {
    temp_dir: tempfile::TempDir,
    pub gh_args_path: std::path::PathBuf,
    _path_guard: env_mock::PathGuard,
}

#[cfg(test)]
impl GhLabelsCommandTestEnvironment {
    pub(crate) fn temp_dir(&self) -> &tempfile::TempDir {
        &self.temp_dir
    }
}

#[cfg(test)]
pub(crate) fn setup_gh_labels_command_test_environment()
-> Result<GhLabelsCommandTestEnvironment, Box<dyn std::error::Error>> {
    let temp_dir = tempfile::tempdir()?;
    let git_args_path = temp_dir.path().join("git_args.txt");
    let gh_args_path = temp_dir.path().join("gh_args.txt");

    let bin_path =
        env_mock::create_mock_bin("git", &temp_dir, &git_origin_capture_script(&git_args_path));

    Ok(GhLabelsCommandTestEnvironment {
        temp_dir,
        gh_args_path,
        _path_guard: env_mock::PathGuard::new(&bin_path),
    })
}

#[cfg(test)]
fn git_origin_capture_script(git_args_path: &Path) -> String {
    format!(
        r#"#!/bin/sh
		echo "$@" >> "{}"
		echo "git@github.com:owner/repo.git"
	"#,
        git_args_path.display()
    )
}
