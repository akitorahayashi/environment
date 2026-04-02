//! GitHub repository reference normalization.

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RepositoryRef {
    host: Option<String>,
    owner: String,
    name: String,
}

use crate::domain::DomainError;

impl RepositoryRef {
    pub fn from_repo_arg(input: &str) -> Result<Self, DomainError> {
        let parts = input.split('/').collect::<Vec<_>>();
        match parts.as_slice() {
            [owner, name] => Self::new(None, owner, name),
            [host, owner, name] => Self::new(Some(*host), owner, name),
            _ => Err(DomainError::InvalidRepositoryRef(format!(
                "invalid repository reference '{input}'"
            ))),
        }
    }

    pub fn from_remote_url(input: &str) -> Result<Self, DomainError> {
        if let Some(rest) = input.strip_prefix("git@") {
            return parse_scp_like_remote(rest);
        }

        if let Some(rest) = input.strip_prefix("ssh://git@") {
            return parse_ssh_remote(rest);
        }

        if let Some(rest) = input.strip_prefix("https://") {
            return parse_https_remote(rest);
        }

        if let Some(rest) = input.strip_prefix("http://") {
            return parse_https_remote(rest);
        }

        Err(DomainError::UnsupportedRemoteUrl(input.to_owned()))
    }

    pub fn as_gh_repo_arg(&self) -> String {
        match &self.host {
            Some(host) => format!("{host}/{}/{}", self.owner, self.name),
            None => format!("{}/{}", self.owner, self.name),
        }
    }

    fn new(host: Option<&str>, owner: &str, name: &str) -> Result<Self, DomainError> {
        if owner.is_empty() || name.is_empty() {
            return Err(DomainError::InvalidRepositoryRef(
                "repository owner and name must not be empty".into(),
            ));
        }

        Ok(Self {
            host: host.map(ToOwned::to_owned),
            owner: owner.to_owned(),
            name: name.trim_end_matches(".git").to_owned(),
        })
    }
}

fn parse_scp_like_remote(input: &str) -> Result<RepositoryRef, DomainError> {
    let (host, path) = input.split_once(':').ok_or_else(|| {
        DomainError::InvalidRepositoryRef(format!("invalid ssh remote '{input}'"))
    })?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn parse_ssh_remote(input: &str) -> Result<RepositoryRef, DomainError> {
    let (host, path) = input.split_once('/').ok_or_else(|| {
        DomainError::InvalidRepositoryRef(format!("invalid ssh remote '{input}'"))
    })?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn parse_https_remote(input: &str) -> Result<RepositoryRef, DomainError> {
    let (host, path) = input.split_once('/').ok_or_else(|| {
        DomainError::InvalidRepositoryRef(format!("invalid https remote '{input}'"))
    })?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn split_owner_name(path: &str) -> Result<(&str, &str), DomainError> {
    let trimmed = path.trim_start_matches('/');
    let parts = trimmed.split('/').collect::<Vec<_>>();
    match parts.as_slice() {
        [owner, name] => Ok((owner, name)),
        _ => Err(DomainError::InvalidRepositoryRef(format!("invalid repository path '{path}'"))),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_owner_name_repo_arg() {
        let repo = RepositoryRef::from_repo_arg("owner/repo").expect("repo arg should parse");
        assert_eq!(repo.as_gh_repo_arg(), "owner/repo");
    }

    #[test]
    fn parses_host_owner_name_repo_arg() {
        let repo = RepositoryRef::from_repo_arg("github.example.com/owner/repo")
            .expect("repo arg should parse");
        assert_eq!(repo.as_gh_repo_arg(), "github.example.com/owner/repo");
    }

    #[test]
    fn parses_https_remote_url() {
        let repo = RepositoryRef::from_remote_url("https://github.com/owner/repo.git")
            .expect("https remote should parse");
        assert_eq!(repo.as_gh_repo_arg(), "github.com/owner/repo");
    }

    #[test]
    fn parses_ssh_remote_url() {
        let repo = RepositoryRef::from_remote_url("git@github.com:owner/repo.git")
            .expect("ssh remote should parse");
        assert_eq!(repo.as_gh_repo_arg(), "github.com/owner/repo");
    }

    #[test]
    fn from_remote_url_parses_scp_like_ssh() {
        let repo = RepositoryRef::from_remote_url("git@github.com:owner/repo.git")
            .expect("scp-like ssh remote should parse");
        assert_eq!(repo.host.as_deref(), Some("github.com"));
        assert_eq!(repo.owner, "owner");
        assert_eq!(repo.name, "repo");
    }

    #[test]
    fn from_remote_url_parses_standard_ssh() {
        let repo = RepositoryRef::from_remote_url("ssh://git@github.com/owner/repo.git")
            .expect("standard ssh remote should parse");
        assert_eq!(repo.host.as_deref(), Some("github.com"));
        assert_eq!(repo.owner, "owner");
        assert_eq!(repo.name, "repo");
    }

    #[test]
    fn from_remote_url_parses_http() {
        let repo = RepositoryRef::from_remote_url("http://github.com/owner/repo.git")
            .expect("http remote should parse");
        assert_eq!(repo.host.as_deref(), Some("github.com"));
        assert_eq!(repo.owner, "owner");
        assert_eq!(repo.name, "repo");
    }

    #[test]
    fn from_remote_url_fails_on_unsupported_url() {
        let result = RepositoryRef::from_remote_url("ftp://github.com/owner/repo.git");
        assert!(result.is_err());
    }

    #[test]
    fn from_repo_arg_fails_on_invalid_format() {
        let cases = ["just-one-part", "host/owner/repo/extra"];
        for input in cases {
            assert!(
                RepositoryRef::from_repo_arg(input).is_err(),
                "from_repo_arg should fail for '{input}'"
            );
        }
    }

    #[test]
    fn from_repo_arg_fails_on_empty_owner_or_name() {
        let cases = ["/repo", "owner/", "/", "host//repo", "host/owner/"];
        for input in cases {
            assert!(
                RepositoryRef::from_repo_arg(input).is_err(),
                "from_repo_arg should fail for '{input}'"
            );
        }
    }

    #[test]
    fn from_remote_url_fails_on_invalid_ssh_remote() {
        let cases = ["git@github.com", "ssh://git@github.com"];
        for input in cases {
            assert!(
                RepositoryRef::from_remote_url(input).is_err(),
                "from_remote_url should fail for '{input}'"
            );
        }
    }

    #[test]
    fn from_remote_url_fails_on_invalid_https_remote() {
        let cases = ["https://github.com", "https://github.com/owner"];
        for input in cases {
            assert!(
                RepositoryRef::from_remote_url(input).is_err(),
                "from_remote_url should fail for '{input}'"
            );
        }
    }
}
