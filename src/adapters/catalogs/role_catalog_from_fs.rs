//! Role catalog resolved from filesystem role directories.

use std::path::PathBuf;

use crate::domain::error::AppError;
use crate::domain::ports::role_catalog::RoleCatalog;

pub struct FsRoleCatalog {
    roles_dir: PathBuf,
}

impl FsRoleCatalog {
    pub fn new(roles_dir: PathBuf) -> Self {
        Self { roles_dir }
    }
}

impl RoleCatalog for FsRoleCatalog {
    fn roles_with_config(&self) -> Result<Vec<String>, AppError> {
        let entries = std::fs::read_dir(&self.roles_dir).map_err(|e| {
            AppError::Config(format!(
                "failed to read roles directory '{}': {e}",
                self.roles_dir.display()
            ))
        })?;
        let mut roles = Vec::new();
        for entry in entries {
            let entry =
                entry.map_err(|e| AppError::Config(format!("failed to read role entry: {e}")))?;
            let path = entry.path();
            if path.is_dir()
                && path.join("config").is_dir()
                && let Some(name) = path.file_name().and_then(|n| n.to_str())
            {
                roles.push(name.to_string());
            }
        }
        roles.sort();
        Ok(roles)
    }
}
