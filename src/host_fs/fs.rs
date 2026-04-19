//! Filesystem port — interface for file system operations.

use std::path::{Path, PathBuf};

use crate::error::AppError;

/// Provides file system operations.
pub trait FsPort {
    /// Check whether a path exists.
    fn exists(&self, path: &Path) -> bool;

    /// Read a file to a string.
    fn read_to_string(&self, path: &Path) -> Result<String, AppError>;

    /// List entries in a directory.
    fn read_dir(&self, path: &Path) -> Result<Vec<PathBuf>, AppError>;

    /// Write content to a file.
    fn write(&self, path: &Path, content: &[u8]) -> Result<(), AppError>;

    /// Create a directory and all parent directories.
    fn create_dir_all(&self, path: &Path) -> Result<(), AppError>;

    /// Remove a directory and all of its contents.
    fn remove_dir_all(&self, path: &Path) -> Result<(), AppError>;

    /// Copy a file from one location to another.
    fn copy(&self, from: &Path, to: &Path) -> Result<u64, AppError>;

    /// Rename a file or directory.
    fn rename(&self, from: &Path, to: &Path) -> Result<(), AppError>;

    /// Check whether a path exists and is a directory.
    fn is_dir(&self, path: &Path) -> bool;
}
