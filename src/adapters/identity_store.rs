//! Identity store adapter — JSON persistence on local disk.
//!
//! The base path is `~/.config/` — the project convention for macOS.
//! Ansible roles reference `local_config_root` as an extra var and expect
//! `~/.config/mev/roles/`, so this path must not change.

use std::path::{Path, PathBuf};

use crate::domain::error::AppError;
use crate::domain::identity::{Identity, IdentityScope};
use crate::domain::ports::identity_store::{IdentityState, IdentityStore};

fn dot_config_dir() -> Result<PathBuf, AppError> {
    dirs::home_dir()
        .map(|h| h.join(".config"))
        .ok_or_else(|| AppError::Config("home directory could not be resolved".to_string()))
}

/// Default path to the mev identity configuration file.
pub fn default_identity_path() -> Result<PathBuf, AppError> {
    Ok(dot_config_dir()?.join("mev").join("identity.json"))
}

/// Default path to the local config root for deployed role configs.
pub fn local_config_root() -> Result<PathBuf, AppError> {
    Ok(dot_config_dir()?.join("mev").join("roles"))
}

pub struct IdentityFileStore {
    identity_path: PathBuf,
}

impl IdentityFileStore {
    pub fn new(identity_path: PathBuf) -> Self {
        Self { identity_path }
    }
}

impl IdentityStore for IdentityFileStore {
    fn exists(&self) -> bool {
        self.identity_path.exists()
    }

    fn load(&self) -> Result<IdentityState, AppError> {
        if self.identity_path.exists() {
            let content = std::fs::read_to_string(&self.identity_path)?;
            return serde_json::from_str(&content)
                .map_err(|e| AppError::Config(format!("failed to parse identity config: {e}")));
        }

        Err(AppError::Config("identity configuration does not exist".to_string()))
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

    fn get_identity(&self, identity: IdentityScope) -> Result<Option<Identity>, AppError> {
        let state = self.load()?;
        match identity {
            IdentityScope::Personal => Ok(Some(state.personal)),
            IdentityScope::Work => Ok(Some(state.work)),
        }
    }

    fn identity_path(&self) -> &Path {
        self.identity_path.as_path()
    }
}

#[cfg(test)]
mod tests {
    use super::IdentityFileStore;
    use crate::domain::identity::{Identity, IdentityScope};
    use crate::domain::ports::identity_store::{IdentityState, IdentityStore};
    use std::path::PathBuf;
    use tempfile::tempdir;

    fn create_dummy_state() -> IdentityState {
        IdentityState {
            personal: Identity {
                name: "Personal Name".to_string(),
                email: "personal@example.com".to_string(),
            },
            work: Identity { name: "Work Name".to_string(), email: "work@example.com".to_string() },
        }
    }

    #[test]
    fn exists_returns_false_when_neither_exist() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("identity.json");
        let store = IdentityFileStore::new(path);

        assert!(!store.exists());
        Ok(())
    }

    #[test]
    fn exists_returns_true_when_identity_exists() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("identity.json");
        std::fs::write(&path, "{}")?;

        let store = IdentityFileStore::new(path);
        assert!(store.exists());
        Ok(())
    }

    #[test]
    fn load_fails_when_neither_exists() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("identity.json");
        let store = IdentityFileStore::new(path);

        assert!(store.load().is_err());
        Ok(())
    }

    #[test]
    fn load_succeeds_from_new_path() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("identity.json");
        let state = create_dummy_state();
        let content = serde_json::to_string(&state)?;
        std::fs::write(&path, content)?;

        let store = IdentityFileStore::new(path);
        let loaded = store.load()?;
        assert_eq!(loaded.personal.email, "personal@example.com");
        Ok(())
    }

    #[test]
    fn save_writes_atomically() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("nested").join("identity.json");
        let store = IdentityFileStore::new(path.clone());

        let state = create_dummy_state();
        store.save(&state)?;

        assert!(path.exists());

        let content = std::fs::read_to_string(&path)?;
        let loaded: IdentityState = serde_json::from_str(&content)?;
        assert_eq!(loaded.work.name, "Work Name");
        Ok(())
    }

    #[test]
    fn save_fails_without_parent() -> Result<(), Box<dyn std::error::Error>> {
        let path = PathBuf::from("");
        let store = IdentityFileStore::new(path);

        let state = create_dummy_state();
        assert!(store.save(&state).is_err());
        Ok(())
    }

    #[test]
    fn get_identity_returns_correct_variants() -> Result<(), Box<dyn std::error::Error>> {
        let dir = tempdir()?;
        let path = dir.path().join("identity.json");
        let store = IdentityFileStore::new(path);

        let state = create_dummy_state();
        store.save(&state)?;

        let personal = store.get_identity(IdentityScope::Personal)?.ok_or("missing personal")?;
        assert_eq!(personal.name, "Personal Name");

        let work = store.get_identity(IdentityScope::Work)?.ok_or("missing work")?;
        assert_eq!(work.name, "Work Name");

        Ok(())
    }
}
