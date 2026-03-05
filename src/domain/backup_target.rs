//! Backup target resolution and metadata.

use std::fmt;

/// Supported backup targets.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackupTarget {
    System,
    Vscode,
}

impl BackupTarget {
    /// Resolve a user input string to a backup target.
    pub fn from_input(s: &str) -> Option<Self> {
        match s {
            "system" => Some(Self::System),
            "vscode" | "vscode-extensions" => Some(Self::Vscode),
            _ => None,
        }
    }

    /// All available backup targets.
    pub fn all() -> &'static [Self] {
        &[Self::System, Self::Vscode]
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
        "common"
    }
}

impl fmt::Display for BackupTarget {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn backup_target_resolves_system() {
        assert_eq!(BackupTarget::from_input("system"), Some(BackupTarget::System));
    }

    #[test]
    fn backup_target_resolves_vscode() {
        assert_eq!(BackupTarget::from_input("vscode"), Some(BackupTarget::Vscode));
    }

    #[test]
    fn backup_target_resolves_vscode_extensions_alias() {
        assert_eq!(BackupTarget::from_input("vscode-extensions"), Some(BackupTarget::Vscode));
    }

    #[test]
    fn backup_target_rejects_unknown() {
        assert_eq!(BackupTarget::from_input("unknown"), None);
    }

    #[test]
    fn backup_target_all_returns_expected_set() {
        assert_eq!(BackupTarget::all(), &[BackupTarget::System, BackupTarget::Vscode]);
    }
}
