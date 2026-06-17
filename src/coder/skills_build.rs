//! Reconcile the intermediate skills directory to hold exactly the enabled skills.
//!
//! Each enabled skill becomes a symlink `skills_dir/<name>` pointing at the deployed
//! source `source_dir/<name>`. Disabled or removed skills have their symlink removed.
//! Agent skill directories symlink to these entries, so updating this directory reflects
//! everywhere without re-running provisioning.

use std::path::Path;

use crate::error::AppError;
use crate::host_fs::fs::FsPort;

/// Make `skills_dir` contain exactly one symlink per enabled skill into `source_dir`.
pub fn build(
    fs: &dyn FsPort,
    source_dir: &Path,
    enabled: &[String],
    skills_dir: &Path,
) -> Result<(), AppError> {
    fs.create_dir_all(skills_dir)?;

    // Remove managed symlinks that are no longer enabled.
    for entry in fs.read_dir(skills_dir)? {
        if !fs.is_symlink(&entry) {
            continue;
        }
        let name = match entry.file_name().and_then(|n| n.to_str()) {
            Some(name) => name.to_string(),
            None => continue,
        };
        if !enabled.iter().any(|e| e == &name) {
            fs.remove_file(&entry)?;
        }
    }

    // Ensure every enabled skill has a symlink into the deployed source.
    for name in enabled {
        let link = skills_dir.join(name);
        let target = source_dir.join(name);
        if fs.is_symlink(&link) {
            if fs.read_link(&link).map(|t| t == target).unwrap_or(false) {
                continue;
            }
            fs.remove_file(&link)?;
        } else if fs.exists(&link) {
            return Err(AppError::Config(format!(
                "skills entry '{}' already exists and is not a managed symlink",
                link.display()
            )));
        }
        fs.symlink(&target, &link)?;
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::host_fs::FakeFsPort;
    use std::path::PathBuf;

    fn source() -> PathBuf {
        PathBuf::from("/src/skills")
    }

    fn intermediate() -> PathBuf {
        PathBuf::from("/cfg/skills")
    }

    #[test]
    fn enabled_skill_links_into_source() {
        let fs = FakeFsPort::new();
        fs.add_dir(&source().join("toon"));

        build(&fs, &source(), &["toon".to_string()], &intermediate()).unwrap();

        let link = intermediate().join("toon");
        assert!(fs.is_symlink(&link));
        assert_eq!(fs.read_link(&link).unwrap(), source().join("toon"));
    }

    #[test]
    fn disabled_skill_link_is_removed() {
        let fs = FakeFsPort::new();
        fs.add_dir(&source().join("toon"));
        fs.add_symlink(&intermediate().join("toon"), &source().join("toon"));

        build(&fs, &source(), &[], &intermediate()).unwrap();

        assert!(!fs.is_symlink(&intermediate().join("toon")));
    }

    #[test]
    fn reconciles_to_exactly_enabled_set() {
        let fs = FakeFsPort::new();
        fs.add_dir(&source().join("toon"));
        fs.add_dir(&source().join("effective-prompting"));
        fs.add_symlink(&intermediate().join("toon"), &source().join("toon"));

        build(&fs, &source(), &["effective-prompting".to_string()], &intermediate()).unwrap();

        assert!(!fs.is_symlink(&intermediate().join("toon")));
        assert!(fs.is_symlink(&intermediate().join("effective-prompting")));
    }

    #[test]
    fn rejects_non_symlink_entry_collision() {
        let fs = FakeFsPort::new();
        fs.add_dir(&source().join("toon"));
        fs.add_file(&intermediate().join("toon"), "not a link");

        assert!(build(&fs, &source(), &["toon".to_string()], &intermediate()).is_err());
    }
}
