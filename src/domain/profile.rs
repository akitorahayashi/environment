//! Profile identifiers and mapping rules.

use crate::domain::error::AppError;

/// Machine-specific profiles that require explicit selection.
pub const MACHINE_PROFILES: &[&str] = &["macbook", "mac-mini"];

/// All valid profile identifiers including "common".
pub const VALID_PROFILES: &[&str] = &["common", "macbook", "mac-mini"];

/// Profile alias mappings.
pub const PROFILE_ALIASES: &[(&str, &str)] =
    &[("mbk", "macbook"), ("mmn", "mac-mini"), ("cmn", "common")];

/// Resolve a profile identifier or alias to its canonical name.
pub fn resolve_profile(input: &str) -> Option<&'static str> {
    // Direct match
    for &profile in VALID_PROFILES {
        if input == profile {
            return Some(profile);
        }
    }
    // Alias match
    for &(alias, canonical) in PROFILE_ALIASES {
        if input == alias {
            return Some(canonical);
        }
    }
    None
}

/// Validate that a profile is a machine-specific profile (required for `create`).
pub fn validate_machine_profile(input: &str) -> Result<&'static str, AppError> {
    let resolved =
        resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))?;

    if !MACHINE_PROFILES.contains(&resolved) {
        return Err(AppError::InvalidProfile(format!(
            "'{input}' is not a machine profile. Valid: {}",
            MACHINE_PROFILES.join(", ")
        )));
    }

    Ok(resolved)
}

/// Validate any profile including "common" (required for `make`).
pub fn validate_profile(input: &str) -> Result<&'static str, AppError> {
    resolve_profile(input).ok_or_else(|| AppError::InvalidProfile(input.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_canonical_profiles() {
        assert_eq!(resolve_profile("common"), Some("common"));
        assert_eq!(resolve_profile("macbook"), Some("macbook"));
        assert_eq!(resolve_profile("mac-mini"), Some("mac-mini"));
    }

    #[test]
    fn resolves_aliases() {
        assert_eq!(resolve_profile("mbk"), Some("macbook"));
        assert_eq!(resolve_profile("mmn"), Some("mac-mini"));
        assert_eq!(resolve_profile("cmn"), Some("common"));
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
        assert!(matches!(validate_machine_profile("macbook"), Ok("macbook")));
        assert!(matches!(validate_machine_profile("mbk"), Ok("macbook")));
    }
}
