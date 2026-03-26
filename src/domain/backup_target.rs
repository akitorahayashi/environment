//! Backup target resolution and metadata.

use std::fmt;

use crate::domain::error::AppError;

/// Supported backup targets.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackupTarget {
    System,
    Vscode,
}

impl BackupTarget {
    /// All available backup targets.
    pub fn all() -> &'static [Self] {
        ALL_TARGETS
    }

    /// Human-readable name.
    pub fn name(self) -> &'static str {
        match self {
            Self::System => "system",
            Self::Vscode => "vscode",
        }
    }

    /// Description for help display.
    pub fn description(self) -> &'static str {
        match self {
            Self::System => "Backup macOS system defaults",
            Self::Vscode => "Backup VSCode extensions list",
        }
    }

    /// Ansible role name providing definitions for this target.
    pub fn role(self) -> &'static str {
        match self {
            Self::System => "system",
            Self::Vscode => "editor",
        }
    }

    /// Subdirectory within the role config directory.
    pub fn subpath(self) -> &'static str {
        "global"
    }
}

impl fmt::Display for BackupTarget {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

/// All available backup targets.
const ALL_TARGETS: &[BackupTarget] = &[BackupTarget::System, BackupTarget::Vscode];

/// Input aliases mapping user-supplied strings to `BackupTarget` variants.
const BACKUP_TARGET_ALIASES: &[(&str, BackupTarget)] = &[
    ("system", BackupTarget::System),
    ("vscode", BackupTarget::Vscode),
    ("vscode-extensions", BackupTarget::Vscode),
];

/// Resolve a backup target identifier or alias to a `BackupTarget`.
pub fn resolve_backup_target(input: &str) -> Option<BackupTarget> {
    BACKUP_TARGET_ALIASES.iter().find(|&&(alias, _)| alias == input).map(|&(_, target)| target)
}

/// Validate that the input maps to a `BackupTarget`.
pub fn validate_backup_target(input: &str) -> Result<BackupTarget, AppError> {
    resolve_backup_target(input).ok_or_else(|| {
        let valid: Vec<_> = BackupTarget::all().iter().map(|t| t.name()).collect();
        AppError::InvalidBackupTarget(format!(
            "'{input}' is not a valid target. Valid targets: {}",
            valid.join(", ")
        ))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn backup_target_resolves_system() {
        assert_eq!(resolve_backup_target("system"), Some(BackupTarget::System));
    }

    #[test]
    fn backup_target_resolves_vscode() {
        assert_eq!(resolve_backup_target("vscode"), Some(BackupTarget::Vscode));
    }

    #[test]
    fn backup_target_resolves_vscode_extensions_alias() {
        assert_eq!(resolve_backup_target("vscode-extensions"), Some(BackupTarget::Vscode));
    }

    #[test]
    fn backup_target_rejects_unknown() {
        assert_eq!(resolve_backup_target("unknown"), None);
    }

    #[test]
    fn backup_target_validates_system() {
        assert_eq!(validate_backup_target("system").unwrap(), BackupTarget::System);
    }

    #[test]
    fn backup_target_validate_rejects_unknown() {
        let err = validate_backup_target("unknown").unwrap_err();
        match err {
            AppError::InvalidBackupTarget(msg) => {
                assert!(msg.contains("'unknown' is not a valid target"));
            }
            _ => panic!("Expected InvalidBackupTarget error"),
        }
    }

    #[test]
    fn backup_target_all_returns_expected_set() {
        assert_eq!(BackupTarget::all(), &[BackupTarget::System, BackupTarget::Vscode]);
    }

    #[test]
    fn backup_target_subpath_is_global_for_all_targets() {
        for target in BackupTarget::all() {
            assert_eq!(target.subpath(), "global");
        }
    }
}
