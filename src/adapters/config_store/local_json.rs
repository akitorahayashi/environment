//! Configuration file store using JSON on disk.

use std::path::PathBuf;

use crate::domain::error::AppError;
use crate::domain::ports::config_store::{ConfigStore, MevConfig};
use crate::domain::vcs_identity::VcsIdentity;

pub struct ConfigFileStore {
    config_path: PathBuf,
}

impl ConfigFileStore {
    pub fn new(config_path: PathBuf) -> Self {
        Self { config_path }
    }
}

impl ConfigStore for ConfigFileStore {
    fn exists(&self) -> bool {
        self.config_path.exists()
    }

    fn load(&self) -> Result<MevConfig, AppError> {
        let content = std::fs::read_to_string(&self.config_path)?;
        serde_json::from_str(&content)
            .map_err(|e| AppError::Config(format!("failed to parse config: {e}")))
    }

    fn save(&self, config: &MevConfig) -> Result<(), AppError> {
        let parent = self
            .config_path
            .parent()
            .ok_or_else(|| AppError::Config("config path has no parent directory".to_string()))?;
        std::fs::create_dir_all(parent)?;

        let content = serde_json::to_string_pretty(config)
            .map_err(|e| AppError::Config(format!("failed to serialize config: {e}")))?;

        // Atomic write: write to temp file in same directory, then rename.
        let tmp_path = parent.join(".config.json.tmp");
        std::fs::write(&tmp_path, &content)
            .map_err(|e| AppError::Config(format!("failed to write temp config: {e}")))?;
        std::fs::rename(&tmp_path, &self.config_path).map_err(|e| {
            let _ = std::fs::remove_file(&tmp_path);
            AppError::Config(format!("failed to rename temp config: {e}"))
        })?;
        Ok(())
    }

    fn get_identity(&self, profile: &str) -> Result<Option<VcsIdentity>, AppError> {
        let config = self.load()?;
        match profile {
            "personal" => Ok(Some(config.personal)),
            "work" => Ok(Some(config.work)),
            _ => Ok(None),
        }
    }

    fn config_path(&self) -> PathBuf {
        self.config_path.clone()
    }
}
