//! VCS identity model and switch identity resolution.
//!
//! `VcsIdentity` is a mev-specific concept: it represents the name/email pair
//! stored per identity (personal / work) and applied to Git and Jujutsu.

use std::fmt;

/// Name and email pair applied to global VCS configuration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct VcsIdentity {
    pub name: String,
    pub email: String,
}

/// A resolved, valid VCS identity target for switching.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SwitchIdentity {
    Personal,
    Work,
}

impl SwitchIdentity {
    /// Canonical string representation used for storage lookups and display.
    pub fn as_str(&self) -> &'static str {
        match self {
            Self::Personal => "personal",
            Self::Work => "work",
        }
    }
}

impl fmt::Display for SwitchIdentity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Input aliases mapping user-supplied strings to `SwitchIdentity` variants.
const SWITCH_IDENTITY_ALIASES: &[(&str, SwitchIdentity)] = &[
    ("p", SwitchIdentity::Personal),
    ("personal", SwitchIdentity::Personal),
    ("w", SwitchIdentity::Work),
    ("work", SwitchIdentity::Work),
];

/// Resolve a switch identity input (alias or canonical) to a `SwitchIdentity`.
pub fn resolve_switch_identity(input: &str) -> Option<SwitchIdentity> {
    let lower = input.to_lowercase();
    for (alias, identity) in SWITCH_IDENTITY_ALIASES {
        if lower == *alias {
            return Some(*identity);
        }
    }
    None
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_switch_identities() {
        assert_eq!(resolve_switch_identity("p"), Some(SwitchIdentity::Personal));
        assert_eq!(resolve_switch_identity("personal"), Some(SwitchIdentity::Personal));
        assert_eq!(resolve_switch_identity("w"), Some(SwitchIdentity::Work));
        assert_eq!(resolve_switch_identity("work"), Some(SwitchIdentity::Work));
        assert_eq!(resolve_switch_identity("unknown"), None);
    }

    #[test]
    fn switch_identity_as_str_roundtrips() {
        assert_eq!(SwitchIdentity::Personal.as_str(), "personal");
        assert_eq!(SwitchIdentity::Work.as_str(), "work");
    }
}
