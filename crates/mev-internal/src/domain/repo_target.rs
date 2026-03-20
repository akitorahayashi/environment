//! Repository target resolution.

use crate::domain::repository_ref::RepositoryRef;

pub fn resolve_repo_ref(
    explicit_repo: Option<&str>,
    origin_url: Option<&str>,
) -> Result<RepositoryRef, Box<dyn std::error::Error>> {
    if let Some(explicit_repo) = explicit_repo {
        return RepositoryRef::from_repo_arg(explicit_repo);
    }

    if let Some(origin_url) = origin_url {
        return RepositoryRef::from_remote_url(origin_url);
    }

    Err("could not determine repository: pass --repo or run inside a git repository with origin"
        .into())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn prefers_explicit_repo() {
        let repo = resolve_repo_ref(Some("owner/repo"), Some("https://github.com/other/repo.git"))
            .expect("explicit repo should win");
        assert_eq!(repo.as_gh_repo_arg(), "owner/repo");
    }

    #[test]
    fn falls_back_to_origin_url() {
        let repo = resolve_repo_ref(None, Some("git@github.com:owner/repo.git"))
            .expect("origin url should resolve");
        assert_eq!(repo.as_gh_repo_arg(), "github.com/owner/repo");
    }

    #[test]
    fn fails_when_both_none() {
        assert!(resolve_repo_ref(None, None).is_err());
    }

    #[test]
    fn explicit_repo_only() {
        let repo = resolve_repo_ref(Some("owner/repo"), None)
            .expect("explicit repo without origin should win");
        assert_eq!(repo.as_gh_repo_arg(), "owner/repo");
    }
}
