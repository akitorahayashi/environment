//! Resolution of the mev config directory and its well-known entries.
//!
//! The config directory is `~/.config/mev/` — the project convention for macOS.
//! Ansible roles reference `roles_root()` as the `local_config_root` extra var and
//! expect `~/.config/mev/roles/`, so these paths must not change.

use std::path::{Path, PathBuf};

use crate::error::AppError;

/// Resolve `~/.config/mev/` from the resolved home directory.
pub fn root(home_dir: &Path) -> PathBuf {
    home_dir.join(".config").join("mev")
}

/// Resolve `~/.config/mev/identity.json` from the resolved home directory.
pub fn identity_file(home_dir: &Path) -> PathBuf {
    root(home_dir).join("identity.json")
}

/// Resolve `~/.config/mev/roles/` from the resolved home directory.
pub fn roles_root(home_dir: &Path) -> PathBuf {
    root(home_dir).join("roles")
}

/// Resolve the home directory or surface a typed configuration error.
pub fn home() -> Result<PathBuf, AppError> {
    dirs::home_dir()
        .ok_or_else(|| AppError::Config("home directory could not be resolved".to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entries_resolve_under_dot_config_mev() {
        let home = Path::new("/Users/tester");
        assert_eq!(root(home), PathBuf::from("/Users/tester/.config/mev"));
        assert_eq!(identity_file(home), PathBuf::from("/Users/tester/.config/mev/identity.json"));
        assert_eq!(roles_root(home), PathBuf::from("/Users/tester/.config/mev/roles"));
    }
}
