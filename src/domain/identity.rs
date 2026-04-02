//! Git identity model and identity scope resolution.
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
pub enum IdentityScope {
    Personal,
    Work,
}

impl IdentityScope {
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

impl fmt::Display for IdentityScope {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Resolve a identity scope input (alias or canonical) to a `IdentityScope`.
pub fn resolve_identity_scope(input: &str) -> Option<IdentityScope> {
    let lower = input.to_lowercase();
    IdentityScope::all()
        .iter()
        .find(|identity| lower == identity.as_str() || identity.aliases().contains(&lower.as_str()))
        .copied()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_identity_scopes() {
        assert_eq!(resolve_identity_scope("p"), Some(IdentityScope::Personal));
        assert_eq!(resolve_identity_scope("personal"), Some(IdentityScope::Personal));
        assert_eq!(resolve_identity_scope("w"), Some(IdentityScope::Work));
        assert_eq!(resolve_identity_scope("work"), Some(IdentityScope::Work));
        assert_eq!(resolve_identity_scope("unknown"), None);
    }

    #[test]
    fn identity_scope_as_str_roundtrips() {
        assert_eq!(IdentityScope::Personal.as_str(), "personal");
        assert_eq!(IdentityScope::Work.as_str(), "work");
    }
}
