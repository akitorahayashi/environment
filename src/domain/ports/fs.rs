//! Filesystem port — interface for file system operations.

use std::path::{Path, PathBuf};

use crate::domain::error::AppError;

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
}
