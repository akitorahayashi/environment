//! Shared testing harness for `mev` integration tests.

use assert_cmd::Command;
use std::os::unix::fs::PermissionsExt;
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

    /// Create an executable mock command in the test working directory.
    pub(crate) fn create_mock_command(&self, name: &str, script: &str) {
        let command_path = self.work_dir.join(name);
        std::fs::write(&command_path, script).expect("Failed to write mock command");

        let mut perms = std::fs::metadata(&command_path)
            .expect("Failed to read mock command metadata")
            .permissions();
        perms.set_mode(0o755);
        std::fs::set_permissions(&command_path, perms)
            .expect("Failed to set mock command permissions");
    }

    /// Build PATH with the working directory prepended for command mocking.
    pub(crate) fn path_with_mock_commands(&self) -> String {
        let current_path = std::env::var("PATH").unwrap_or_default();
        format!("{}:{}", self.work_dir.display(), current_path)
    }

    /// Path to the isolated working directory.
    #[allow(dead_code)]
    pub(crate) fn work_dir(&self) -> &PathBuf {
        &self.work_dir
    }
}
