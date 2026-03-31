//! Profile identifiers and mapping rules.

use std::fmt;

use crate::domain::error::AppError;

/// A resolved, valid provisioning profile.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    Macbook,
    MacMini,
    Global,
}

impl Profile {
    /// Canonical string representation passed to Ansible.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Macbook => "macbook",
            Self::MacMini => "mac-mini",
            Self::Global => "global",
        }
    }

    fn is_hardware_profile(&self) -> bool {
        matches!(self, Self::Macbook | Self::MacMini)
    }

    /// Input aliases for this profile (excluding the canonical name).
    pub fn aliases(&self) -> &'static [&'static str] {
        match self {
            Self::Macbook => &["mbk"],
            Self::MacMini => &["mmn"],
            Self::Global => &["glb"],
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
    &[Profile::Global, Profile::Macbook, Profile::MacMini]
}

/// Input aliases mapping user-supplied strings to `Profile` variants.
const PROFILE_ALIASES: &[(&str, Profile)] = &[
    ("macbook", Profile::Macbook),
    ("mbk", Profile::Macbook),
    ("mac-mini", Profile::MacMini),
    ("mmn", Profile::MacMini),
    ("global", Profile::Global),
    ("glb", Profile::Global),
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

/// Validate that the input maps to a hardware-specific profile (required for `create`).
pub fn validate_hardware_profile(input: &str) -> Result<Profile, AppError> {
    let profile =
        resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))?;
    if !profile.is_hardware_profile() {
        return Err(AppError::InvalidProfile(format!(
            "'{input}' is not a hardware profile. Valid: {}",
            all_profiles()
                .iter()
                .filter(|p| p.is_hardware_profile())
                .map(Profile::as_str)
                .collect::<Vec<_>>()
                .join(", ")
        )));
    }
    Ok(profile)
}

/// Validate any profile including `global` (required for `make`).
pub fn validate_profile(input: &str) -> Result<Profile, AppError> {
    resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_canonical_profiles() {
        assert_eq!(resolve_profile("global"), Some(Profile::Global));
        assert_eq!(resolve_profile("macbook"), Some(Profile::Macbook));
        assert_eq!(resolve_profile("mac-mini"), Some(Profile::MacMini));
    }

    #[test]
    fn resolves_aliases() {
        assert_eq!(resolve_profile("mbk"), Some(Profile::Macbook));
        assert_eq!(resolve_profile("mmn"), Some(Profile::MacMini));
        assert_eq!(resolve_profile("glb"), Some(Profile::Global));
    }

    #[test]
    fn rejects_unknown() {
        assert_eq!(resolve_profile("desktop"), None);
    }

    #[test]
    fn validate_hardware_profile_rejects_global() {
        assert!(validate_hardware_profile("global").is_err());
    }

    #[test]
    fn validate_hardware_profile_accepts_macbook() {
        assert_eq!(validate_hardware_profile("macbook").unwrap(), Profile::Macbook);
        assert_eq!(validate_hardware_profile("mbk").unwrap(), Profile::Macbook);
    }

    #[test]
    fn profile_as_str_roundtrips() {
        assert_eq!(Profile::Macbook.as_str(), "macbook");
        assert_eq!(Profile::MacMini.as_str(), "mac-mini");
        assert_eq!(Profile::Global.as_str(), "global");
    }
}
