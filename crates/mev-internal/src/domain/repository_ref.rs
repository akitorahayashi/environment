//! GitHub repository reference normalization.

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RepositoryRef {
    host: Option<String>,
    owner: String,
    name: String,
}

impl RepositoryRef {
    pub fn from_repo_arg(input: &str) -> Result<Self, Box<dyn std::error::Error>> {
        let parts = input.split('/').collect::<Vec<_>>();
        match parts.as_slice() {
            [owner, name] => Self::new(None, owner, name),
            [host, owner, name] => Self::new(Some(*host), owner, name),
            _ => Err(format!("invalid repository reference '{input}'").into()),
        }
    }

    pub fn from_remote_url(input: &str) -> Result<Self, Box<dyn std::error::Error>> {
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

        Err(format!("unsupported remote url '{input}'").into())
    }

    pub fn as_gh_repo_arg(&self) -> String {
        match &self.host {
            Some(host) => format!("{host}/{}/{}", self.owner, self.name),
            None => format!("{}/{}", self.owner, self.name),
        }
    }

    fn new(
        host: Option<&str>,
        owner: &str,
        name: &str,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        if owner.is_empty() || name.is_empty() {
            return Err("repository owner and name must not be empty".into());
        }

        Ok(Self {
            host: host.map(ToOwned::to_owned),
            owner: owner.to_owned(),
            name: name.trim_end_matches(".git").to_owned(),
        })
    }
}

fn parse_scp_like_remote(input: &str) -> Result<RepositoryRef, Box<dyn std::error::Error>> {
    let (host, path) =
        input.split_once(':').ok_or_else(|| format!("invalid ssh remote '{input}'"))?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn parse_ssh_remote(input: &str) -> Result<RepositoryRef, Box<dyn std::error::Error>> {
    let (host, path) =
        input.split_once('/').ok_or_else(|| format!("invalid ssh remote '{input}'"))?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn parse_https_remote(input: &str) -> Result<RepositoryRef, Box<dyn std::error::Error>> {
    let (host, path) =
        input.split_once('/').ok_or_else(|| format!("invalid https remote '{input}'"))?;
    let (owner, name) = split_owner_name(path)?;
    RepositoryRef::new(Some(host), owner, name)
}

fn split_owner_name(path: &str) -> Result<(&str, &str), Box<dyn std::error::Error>> {
    let trimmed = path.trim_start_matches('/');
    let parts = trimmed.split('/').collect::<Vec<_>>();
    match parts.as_slice() {
        [owner, name] => Ok((owner, name)),
        _ => Err(format!("invalid repository path '{path}'").into()),
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
}
