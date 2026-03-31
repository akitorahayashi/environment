//! Configuration file store using JSON on disk.

use std::path::{Path, PathBuf};

use crate::domain::error::AppError;
use crate::domain::identity::{Identity, SwitchIdentity};
use crate::domain::ports::identity_store::{IdentityState, IdentityStore};

pub struct IdentityFileStore {
    identity_path: PathBuf,
}

impl IdentityFileStore {
    pub fn new(identity_path: PathBuf) -> Self {
        Self { identity_path }
    }

    fn legacy_config_path(&self) -> PathBuf {
        self.identity_path.with_file_name("config.json")
    }
}

impl IdentityStore for IdentityFileStore {
    fn exists(&self) -> bool {
        self.identity_path.exists() || self.legacy_config_path().exists()
    }

    fn load(&self) -> Result<IdentityState, AppError> {
        if self.identity_path.exists() {
            let content = std::fs::read_to_string(&self.identity_path)?;
            return serde_json::from_str(&content)
                .map_err(|e| AppError::Config(format!("failed to parse identity config: {e}")));
        }

        if self.legacy_config_path().exists() {
            let content = std::fs::read_to_string(self.legacy_config_path())?;
            let state: IdentityState = serde_json::from_str(&content).map_err(|e| {
                AppError::Config(format!("failed to parse legacy identity config: {e}"))
            })?;

            // Migrate automatically to the new path.
            if let Err(e) = self.save(&state) {
                eprintln!("Warning: failed to migrate identity config: {e}");
            }
            return Ok(state);
        }

        Err(AppError::Config("no identity configuration found".to_string()))
    }

    fn save(&self, state: &IdentityState) -> Result<(), AppError> {
        let parent = self
            .identity_path
            .parent()
            .ok_or_else(|| AppError::Config("identity path has no parent directory".to_string()))?;
        std::fs::create_dir_all(parent)?;

        let content = serde_json::to_string_pretty(state)
            .map_err(|e| AppError::Config(format!("failed to serialize identity config: {e}")))?;

        // Atomic write: write to temp file in same directory, then rename.
        let tmp_path = parent.join(".identity.json.tmp");
        std::fs::write(&tmp_path, &content)
            .map_err(|e| AppError::Config(format!("failed to write temp identity config: {e}")))?;
        std::fs::rename(&tmp_path, &self.identity_path).map_err(|e| {
            let _ = std::fs::remove_file(&tmp_path);
            AppError::Config(format!("failed to rename temp identity config: {e}"))
        })?;
        Ok(())
    }

    fn get_identity(&self, identity: SwitchIdentity) -> Result<Option<Identity>, AppError> {
        let state = self.load()?;
        match identity {
            SwitchIdentity::Personal => Ok(Some(state.personal)),
            SwitchIdentity::Work => Ok(Some(state.work)),
        }
    }

    fn identity_path(&self) -> &Path {
        self.identity_path.as_path()
    }
}
