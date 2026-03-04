//! VCS identity model and switch profile resolution.
//!
//! `VcsIdentity` is a mev-specific concept: it represents the name/email pair
//! stored per profile (personal / work) and applied to Git and Jujutsu.

/// Name and email pair applied to global VCS configuration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct VcsIdentity {
    pub name: String,
    pub email: String,
}

/// Canonical switch profile identifiers and their input aliases.
pub const SWITCH_PROFILES: &[(&str, &str)] =
    &[("p", "personal"), ("personal", "personal"), ("w", "work"), ("work", "work")];

/// Resolve a switch profile input (alias or canonical) to its canonical name.
pub fn resolve_switch_profile(input: &str) -> Option<&'static str> {
    let lower = input.to_lowercase();
    for &(alias, canonical) in SWITCH_PROFILES {
        if lower == alias {
            return Some(canonical);
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_switch_profiles() {
        assert_eq!(resolve_switch_profile("p"), Some("personal"));
        assert_eq!(resolve_switch_profile("personal"), Some("personal"));
        assert_eq!(resolve_switch_profile("w"), Some("work"));
        assert_eq!(resolve_switch_profile("work"), Some("work"));
        assert_eq!(resolve_switch_profile("unknown"), None);
    }
}
