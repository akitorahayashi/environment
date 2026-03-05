//! VCS identity model and switch identity resolution.
//!
//! `VcsIdentity` is a mev-specific concept: it represents the name/email pair
//! stored per identity (personal / work) and applied to Git and Jujutsu.

/// Name and email pair applied to global VCS configuration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct VcsIdentity {
    pub name: String,
    pub email: String,
}

/// Canonical switch identity identifiers and their input aliases.
pub const SWITCH_IDENTITIES: &[(&str, &str)] =
    &[("p", "personal"), ("personal", "personal"), ("w", "work"), ("work", "work")];

/// Resolve a switch identity input (alias or canonical) to its canonical name.
pub fn resolve_switch_identity(input: &str) -> Option<&'static str> {
    let lower = input.to_lowercase();
    for &(alias, canonical) in SWITCH_IDENTITIES {
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
    fn resolves_switch_identities() {
        assert_eq!(resolve_switch_identity("p"), Some("personal"));
        assert_eq!(resolve_switch_identity("personal"), Some("personal"));
        assert_eq!(resolve_switch_identity("w"), Some("work"));
        assert_eq!(resolve_switch_identity("work"), Some("work"));
        assert_eq!(resolve_switch_identity("unknown"), None);
    }
}
