//! Standard filesystem adapter — thin wrapper around `std::fs`.

use std::path::{Path, PathBuf};

use crate::domain::error::AppError;
use crate::domain::ports::fs::FsPort;

pub struct StdFs;

impl FsPort for StdFs {
    fn exists(&self, path: &Path) -> bool {
        path.exists()
    }

    fn read_to_string(&self, path: &Path) -> Result<String, AppError> {
        std::fs::read_to_string(path).map_err(AppError::Io)
    }

    fn read_dir(&self, path: &Path) -> Result<Vec<PathBuf>, AppError> {
        std::fs::read_dir(path)
            .map_err(AppError::Io)?
            .map(|entry| entry.map(|e| e.path()).map_err(AppError::Io))
            .collect()
    }

    fn write(&self, path: &Path, content: &[u8]) -> Result<(), AppError> {
        std::fs::write(path, content).map_err(AppError::Io)
    }

    fn create_dir_all(&self, path: &Path) -> Result<(), AppError> {
        std::fs::create_dir_all(path).map_err(AppError::Io)
    }
}
