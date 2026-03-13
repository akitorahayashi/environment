//! Shared testing harness for `mev` integration tests.

use assert_cmd::Command;
use std::path::PathBuf;
use tempfile::TempDir;

/// Testing harness providing an isolated environment for CLI exercises.
pub(crate) struct TestContext {
    _root: TempDir,
    work_dir: PathBuf,
}

impl TestContext {
    /// Create a new isolated environment.
    pub(crate) fn new() -> Self {
        let manifest_dir = env!("CARGO_MANIFEST_DIR");
        let test_tmp_dir = std::path::Path::new(manifest_dir).join("target").join("test_tmp");
        std::fs::create_dir_all(&test_tmp_dir).expect("Failed to create target/test_tmp");

        let root = tempfile::TempDir::new_in(&test_tmp_dir)
            .expect("Failed to create temp directory for tests");

        let work_dir = root.path().join("work");
        std::fs::create_dir_all(&work_dir).expect("Failed to create test work directory");

        Self { _root: root, work_dir }
    }

    /// Return a `Command` for the `mev` binary.
    pub(crate) fn cli(&self) -> Command {
        let bin_path = assert_cmd::cargo::cargo_bin!("mev");
        let mut cmd = Command::new(bin_path);
        cmd.current_dir(&self.work_dir);
        cmd.env("HOME", &self.work_dir);
        cmd
    }

    /// Path to the isolated working directory.
    #[allow(dead_code)]
    pub(crate) fn work_dir(&self) -> &PathBuf {
        &self.work_dir
    }
}
