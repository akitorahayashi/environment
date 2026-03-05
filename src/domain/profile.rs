//! Profile identifiers and mapping rules.

use std::fmt;

use crate::domain::error::AppError;

/// A resolved, valid provisioning profile.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    Macbook,
    MacMini,
    Common,
}

impl Profile {
    /// Canonical string representation passed to Ansible.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Macbook => "macbook",
            Self::MacMini => "mac-mini",
            Self::Common => "common",
        }
    }

    fn is_machine_profile(&self) -> bool {
        matches!(self, Self::Macbook | Self::MacMini)
    }

    /// Input aliases for this profile (excluding the canonical name).
    pub fn aliases(&self) -> &'static [&'static str] {
        match self {
            Self::Macbook => &["mbk"],
            Self::MacMini => &["mmn"],
            Self::Common => &["cmn"],
        }
    }
}

impl fmt::Display for Profile {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// All profile variants in display order.
pub fn all_profiles() -> &'static [Profile] {
    &[Profile::Common, Profile::Macbook, Profile::MacMini]
}

/// Input aliases mapping user-supplied strings to `Profile` variants.
const PROFILE_ALIASES: &[(&str, Profile)] = &[
    ("macbook", Profile::Macbook),
    ("mbk", Profile::Macbook),
    ("mac-mini", Profile::MacMini),
    ("mmn", Profile::MacMini),
    ("common", Profile::Common),
    ("cmn", Profile::Common),
];

/// Resolve a profile identifier or alias to a `Profile`.
pub fn resolve_profile(input: &str) -> Option<Profile> {
    for &(alias, profile) in PROFILE_ALIASES {
        if input == alias {
            return Some(profile);
        }
    }
    None
}

/// Validate that the input maps to a machine-specific profile (required for `create`).
pub fn validate_machine_profile(input: &str) -> Result<Profile, AppError> {
    let profile =
        resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))?;
    if !profile.is_machine_profile() {
        return Err(AppError::InvalidProfile(format!(
            "'{input}' is not a machine profile. Valid: {}",
            all_profiles()
                .iter()
                .filter(|p| p.is_machine_profile())
                .map(Profile::as_str)
                .collect::<Vec<_>>()
                .join(", ")
        )));
    }
    Ok(profile)
}

/// Validate any profile including `common` (required for `make`).
pub fn validate_profile(input: &str) -> Result<Profile, AppError> {
    resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_canonical_profiles() {
        assert_eq!(resolve_profile("common"), Some(Profile::Common));
        assert_eq!(resolve_profile("macbook"), Some(Profile::Macbook));
        assert_eq!(resolve_profile("mac-mini"), Some(Profile::MacMini));
    }

    #[test]
    fn resolves_aliases() {
        assert_eq!(resolve_profile("mbk"), Some(Profile::Macbook));
        assert_eq!(resolve_profile("mmn"), Some(Profile::MacMini));
        assert_eq!(resolve_profile("cmn"), Some(Profile::Common));
    }

    #[test]
    fn rejects_unknown() {
        assert_eq!(resolve_profile("desktop"), None);
    }

    #[test]
    fn validate_machine_profile_rejects_common() {
        assert!(validate_machine_profile("common").is_err());
    }

    #[test]
    fn validate_machine_profile_accepts_macbook() {
        assert_eq!(validate_machine_profile("macbook").unwrap(), Profile::Macbook);
        assert_eq!(validate_machine_profile("mbk").unwrap(), Profile::Macbook);
    }

    #[test]
    fn profile_as_str_roundtrips() {
        assert_eq!(Profile::Macbook.as_str(), "macbook");
        assert_eq!(Profile::MacMini.as_str(), "mac-mini");
        assert_eq!(Profile::Common.as_str(), "common");
    }
}
