//! Git identity model and identity scope resolution.
//!
//! `Identity` is a mev-specific concept: it represents the name/email pair
//! stored per identity (personal / work) and applied to Git.

use std::fmt;

/// Raw serialization model for Identity.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct RawIdentity {
    pub name: String,
    pub email: String,
}

/// Name and email pair applied to global Git configuration.
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
#[serde(try_from = "RawIdentity", into = "RawIdentity")]
pub struct Identity {
    name: String,
    email: String,
}

impl Identity {
    /// Creates a new identity, ensuring fields are not empty.
    pub fn new(name: impl Into<String>, email: impl Into<String>) -> Option<Self> {
        let name = name.into().trim().to_string();
        let email = email.into().trim().to_string();
        if name.is_empty() || email.is_empty() { None } else { Some(Self { name, email }) }
    }

    /// Gets the name of the identity.
    pub fn name(&self) -> &str {
        &self.name
    }

    /// Gets the email of the identity.
    pub fn email(&self) -> &str {
        &self.email
    }
}

impl std::convert::TryFrom<RawIdentity> for Identity {
    type Error = &'static str;

    fn try_from(raw: RawIdentity) -> Result<Self, Self::Error> {
        Self::new(raw.name, raw.email).ok_or("empty fields")
    }
}

impl From<Identity> for RawIdentity {
    fn from(id: Identity) -> Self {
        Self { name: id.name, email: id.email }
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

/// Look up a switch target corresponding to the user's input.
/// Returns `None` if the input does not match any known canonical name or alias.
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
    fn identity_validation() {
        // Valid inputs
        let id = Identity::new(" Jane Doe ", " jane@example.com ").unwrap();
        assert_eq!(id.name(), "Jane Doe");
        assert_eq!(id.email(), "jane@example.com");

        // Empty or whitespace inputs
        assert!(Identity::new("", "jane@example.com").is_none());
        assert!(Identity::new("  ", "jane@example.com").is_none());
        assert!(Identity::new("Jane Doe", "").is_none());
        assert!(Identity::new("Jane Doe", "  ").is_none());
    }

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
