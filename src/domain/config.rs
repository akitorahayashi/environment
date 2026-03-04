//! Configuration model and invariants.

/// VCS identity for a configuration profile (personal or work).
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct VcsIdentity {
    pub name: String,
    pub email: String,
}

/// Switch profile identifiers.
pub const SWITCH_PROFILES: &[(&str, &str)] =
    &[("p", "personal"), ("personal", "personal"), ("w", "work"), ("work", "work")];

/// Resolve a switch profile identifier.
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
