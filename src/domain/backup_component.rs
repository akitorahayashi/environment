//! Backup component resolution and metadata.

use std::fmt;

use crate::domain::error::AppError;

/// Supported backup components.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum BackupComponent {
    System,
    Vscode,
}

impl BackupComponent {
    /// All available backup components.
    pub fn all() -> &'static [Self] {
        ALL_COMPONENTS
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
            Self::Vscode => "Backup VSCode extensions list and settings",
        }
    }

    /// Ansible role name providing definitions for this component.
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

impl fmt::Display for BackupComponent {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.name())
    }
}

/// All available backup components.
const ALL_COMPONENTS: &[BackupComponent] = &[BackupComponent::System, BackupComponent::Vscode];

/// Input aliases mapping user-supplied strings to `BackupComponent` variants.
const BACKUP_COMPONENT_ALIASES: &[(&str, BackupComponent)] = &[
    ("system", BackupComponent::System),
    ("vscode", BackupComponent::Vscode),
    ("vscode-extensions", BackupComponent::Vscode),
];

/// Look up a backup component corresponding to the user's input.
/// Returns `None` if the input does not map to a known canonical name or alias.
pub fn resolve_backup_component(input: &str) -> Option<BackupComponent> {
    let lower = input.to_lowercase();
    for &(alias, component) in BACKUP_COMPONENT_ALIASES {
        if lower == alias {
            return Some(component);
        }
    }
    None
}

/// Verify the user's input maps to a known component, producing an actionable error if unrecognized.
/// Fails with `AppError::InvalidBackupComponent` if the string cannot be resolved.
pub fn validate_backup_component(input: &str) -> Result<BackupComponent, AppError> {
    resolve_backup_component(input).ok_or_else(|| {
        let valid: Vec<_> = BackupComponent::all().iter().map(|t| t.name()).collect();
        AppError::InvalidBackupComponent(format!(
            "'{input}' is not a valid component. Valid components: {}",
            valid.join(", ")
        ))
    })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn backup_component_resolves_system() {
        assert_eq!(resolve_backup_component("system"), Some(BackupComponent::System));
    }

    #[test]
    fn backup_component_resolves_vscode() {
        assert_eq!(resolve_backup_component("vscode"), Some(BackupComponent::Vscode));
    }

    #[test]
    fn backup_component_resolves_vscode_extensions_alias() {
        assert_eq!(resolve_backup_component("vscode-extensions"), Some(BackupComponent::Vscode));
    }

    #[test]
    fn backup_component_resolves_system_case_insensitively() {
        assert_eq!(resolve_backup_component("SYSTEM"), Some(BackupComponent::System));
    }

    #[test]
    fn backup_component_resolves_vscode_alias_case_insensitively() {
        assert_eq!(resolve_backup_component("VSCODE-EXTENSIONS"), Some(BackupComponent::Vscode));
    }

    #[test]
    fn backup_component_rejects_unknown() {
        assert_eq!(resolve_backup_component("unknown"), None);
    }

    #[test]
    fn backup_component_validates_system() {
        assert_eq!(validate_backup_component("system").unwrap(), BackupComponent::System);
    }

    #[test]
    fn backup_component_validate_rejects_unknown() {
        let err = validate_backup_component("unknown").unwrap_err();
        match err {
            AppError::InvalidBackupComponent(msg) => {
                assert!(msg.contains("'unknown' is not a valid component"));
            }
            _ => panic!("Expected InvalidBackupComponent error"),
        }
    }

    #[test]
    fn backup_component_all_returns_expected_set() {
        assert_eq!(BackupComponent::all(), &[BackupComponent::System, BackupComponent::Vscode]);
    }

    #[test]
    fn backup_component_subpath_is_global_for_all_components() {
        for component in BackupComponent::all() {
            assert_eq!(component.subpath(), "global");
        }
    }
}
