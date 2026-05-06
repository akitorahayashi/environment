//! File identity checks for backup sources and managed targets.

use std::path::Path;

use crate::error::AppError;
use crate::host_fs::fs::FsPort;

pub fn same_file(fs: &dyn FsPort, left: &Path, right: &Path) -> Result<bool, AppError> {
    if !fs.exists(left) || !fs.exists(right) {
        return Ok(false);
    }

    Ok(fs.canonicalize(left)? == fs.canonicalize(right)?)
}
