//! Test helpers for mocking the environment.

use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use tempfile::TempDir;

/// Guard that restores the PATH environment variable when dropped.
pub struct PathGuard {
    original_path: String,
}

impl Drop for PathGuard {
    fn drop(&mut self) {
        unsafe {
            env::set_var("PATH", &self.original_path);
        }
    }
}

/// Guard that restores the current working directory when dropped.
pub struct DirGuard {
    original_dir: PathBuf,
}

impl DirGuard {
    pub fn new(target_dir: &Path) -> Self {
        let original_dir = env::current_dir().unwrap();
        env::set_current_dir(target_dir).unwrap();
        Self { original_dir }
    }
}

impl Drop for DirGuard {
    fn drop(&mut self) {
        let _ = env::set_current_dir(&self.original_dir);
    }
}

/// Creates a mock binary in the given temporary directory and adds it to the PATH.
/// Returns a `PathGuard` to restore the PATH when it goes out of scope.
pub fn create_mock_bin(name: &str, temp_dir: &TempDir, script_content: &str) -> PathGuard {
    let bin_path = temp_dir.path().join(name);
    fs::write(&bin_path, script_content).unwrap();

    let mut perms = fs::metadata(&bin_path).unwrap().permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&bin_path, perms).unwrap();

    let original_path = env::var("PATH").unwrap_or_default();
    let new_path = format!("{}:{}", temp_dir.path().display(), original_path);
    unsafe {
        env::set_var("PATH", new_path);
    }

    PathGuard { original_path }
}
