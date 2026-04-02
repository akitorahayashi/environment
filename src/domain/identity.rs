//! Git identity model and switch identity resolution.
//!
//! `Identity` is a mev-specific concept: it represents the name/email pair
//! stored per identity (personal / work) and applied to Git.

use std::fmt;

/// Name and email pair applied to global Git configuration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct Identity {
    pub name: String,
    pub email: String,
}

impl Identity {
    pub fn is_configured(&self) -> bool {
        !self.name.is_empty() && !self.email.is_empty()
    }
}

/// A resolved, valid identity target for switching.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum SwitchIdentity {
    Personal,
    Work,
}

impl SwitchIdentity {
    /// Canonical string representation used for storage lookups and display.
    pub fn as_str(self) -> &'static str {
        match self {
            Self::Personal => "personal",
            Self::Work => "work",
        }
    }

    /// All available switch identities.
    pub fn all() -> &'static [Self] {
        &[Self::Personal, Self::Work]
    }

    /// Input aliases for this identity (excluding the canonical name).
    pub fn aliases(self) -> &'static [&'static str] {
        match self {
            Self::Personal => &["p"],
            Self::Work => &["w"],
        }
    }
}

impl fmt::Display for SwitchIdentity {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Resolve a switch identity input (alias or canonical) to a `SwitchIdentity`.
pub fn resolve_switch_identity(input: &str) -> Option<SwitchIdentity> {
    let lower = input.to_lowercase();
    SwitchIdentity::all()
        .iter()
        .find(|i| lower == i.as_str() || i.aliases().contains(&lower.as_ref()))
        .copied()
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
