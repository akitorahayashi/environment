//! Resolution of the mev config directory and its well-known entries.
//!
//! The config directory is `~/.config/mev/` — the project convention for macOS.
//! Ansible roles reference `roles_root()` as the `local_config_root` extra var and
//! expect `~/.config/mev/roles/`, so these paths must not change.

use std::path::{Path, PathBuf};

use crate::error::AppError;

/// Resolve `~/.config/mev/` from the resolved home directory.
pub fn root(home_dir: &Path) -> PathBuf {
    home_dir.join(".config").join("mev")
}

/// Resolve `~/.config/mev/identity.json` from the resolved home directory.
pub fn identity_file(home_dir: &Path) -> PathBuf {
    root(home_dir).join("identity.json")
}

/// Resolve `~/.config/mev/roles/` from the resolved home directory.
pub fn roles_root(home_dir: &Path) -> PathBuf {
    root(home_dir).join("roles")
}

/// Resolve the coder generated-entity root `~/.config/mev/coder/`.
///
/// Holds the intermediate AGENTS.md, the intermediate skills directory, and the
/// selection manifests. Kept separate from `roles/` so re-deploying coder sources
/// never overwrites generated entities.
pub fn coder_root(home_dir: &Path) -> PathBuf {
    root(home_dir).join("coder")
}

/// Resolve the generated intermediate `~/.config/mev/coder/AGENTS.md`.
///
/// Built by concatenating the enabled sections; agent tools symlink to this file.
pub fn agents_file(home_dir: &Path) -> PathBuf {
    coder_root(home_dir).join("AGENTS.md")
}

/// Resolve the AGENTS.md selection manifest `~/.config/mev/coder/agents-sections.yml`.
///
/// Holds the `disabled` exclusion list; absence or an empty list enables every section.
pub fn agents_sections_manifest(home_dir: &Path) -> PathBuf {
    coder_root(home_dir).join("agents-sections.yml")
}

/// Resolve the intermediate skills directory `~/.config/mev/coder/skills/`.
///
/// Holds one entry per enabled skill; agent skill directories symlink to these entries.
pub fn skills_dir(home_dir: &Path) -> PathBuf {
    coder_root(home_dir).join("skills")
}

/// Resolve the skills selection manifest `~/.config/mev/coder/skills-selection.yml`.
///
/// Holds the `disabled` exclusion list; absence or an empty list enables every skill.
pub fn skills_selection_manifest(home_dir: &Path) -> PathBuf {
    coder_root(home_dir).join("skills-selection.yml")
}

/// Resolve the deployed AGENTS.md section sources `~/.config/mev/roles/coder/global/agents-sections/`.
///
/// `mk coder` deploys the embedded sources here; concatenation and catalog reads use this copy
/// because the embedded assets do not exist after installation.
pub fn agents_sections_source(home_dir: &Path) -> PathBuf {
    roles_root(home_dir).join("coder").join("global").join("agents-sections")
}

/// Resolve the deployed skills sources `~/.config/mev/roles/coder/global/skills/`.
///
/// `mk coder` deploys the embedded skills here; the catalog is the set of subdirectories.
pub fn skills_source(home_dir: &Path) -> PathBuf {
    roles_root(home_dir).join("coder").join("global").join("skills")
}

/// Resolve the home directory or surface a typed configuration error.
pub fn home() -> Result<PathBuf, AppError> {
    dirs::home_dir()
        .ok_or_else(|| AppError::Config("home directory could not be resolved".to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn entries_resolve_under_dot_config_mev() {
        let home = Path::new("/Users/tester");
        assert_eq!(root(home), PathBuf::from("/Users/tester/.config/mev"));
        assert_eq!(identity_file(home), PathBuf::from("/Users/tester/.config/mev/identity.json"));
        assert_eq!(roles_root(home), PathBuf::from("/Users/tester/.config/mev/roles"));
        assert_eq!(coder_root(home), PathBuf::from("/Users/tester/.config/mev/coder"));
        assert_eq!(agents_file(home), PathBuf::from("/Users/tester/.config/mev/coder/AGENTS.md"));
        assert_eq!(
            agents_sections_manifest(home),
            PathBuf::from("/Users/tester/.config/mev/coder/agents-sections.yml")
        );
        assert_eq!(skills_dir(home), PathBuf::from("/Users/tester/.config/mev/coder/skills"));
        assert_eq!(
            skills_selection_manifest(home),
            PathBuf::from("/Users/tester/.config/mev/coder/skills-selection.yml")
        );
        assert_eq!(
            agents_sections_source(home),
            PathBuf::from("/Users/tester/.config/mev/roles/coder/global/agents-sections")
        );
        assert_eq!(
            skills_source(home),
            PathBuf::from("/Users/tester/.config/mev/roles/coder/global/skills")
        );
    }
}
