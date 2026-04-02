//! Environment mocking for tests.

use std::env;
use std::fs;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use tempfile::TempDir;

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

/// Creates a mock binary in the given temporary directory.
/// Returns a `PathBuf` to the temporary directory path containing the script.
pub fn create_mock_bin(name: &str, temp_dir: &TempDir, script_content: &str) -> PathBuf {
    let bin_path = temp_dir.path().join(name);
    fs::write(&bin_path, script_content).unwrap();

    let mut perms = fs::metadata(&bin_path).unwrap().permissions();
    perms.set_mode(0o755);
    fs::set_permissions(&bin_path, perms).unwrap();

    temp_dir.path().to_path_buf()
}

/// Guard that prepends a directory to the PATH environment variable and restores it when dropped.
/// Note: Tests using this should be marked with #[serial] to avoid environment variable races.
pub struct PathGuard {
    original_path: Option<std::ffi::OsString>,
}

impl PathGuard {
    pub fn new(bin_dir: &Path) -> Self {
        let original_path = env::var_os("PATH");
        let mut paths =
            env::split_paths(original_path.as_deref().unwrap_or_default()).collect::<Vec<_>>();
        paths.insert(0, bin_dir.to_path_buf());
        let new_path = env::join_paths(paths).expect("Failed to construct new PATH");
        // SAFETY: In tests, we ensure thread safety by using the `serial_test` crate.
        #[allow(unused_unsafe)]
        unsafe {
            env::set_var("PATH", new_path);
        }
        Self { original_path }
    }
}

impl Drop for PathGuard {
    fn drop(&mut self) {
        if let Some(original) = &self.original_path {
            // SAFETY: In tests, we ensure thread safety by using the `serial_test` crate.
            #[allow(unused_unsafe)]
            unsafe {
                env::set_var("PATH", original);
            }
        } else {
            // SAFETY: In tests, we ensure thread safety by using the `serial_test` crate.
            #[allow(unused_unsafe)]
            unsafe {
                env::remove_var("PATH");
            }
        }
    }
}
