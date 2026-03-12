//! Locate ansible assets for runtime execution.
//!
//! Resolution order:
//! 1. `CARGO_MANIFEST_DIR/src/assets/ansible` for `cargo run` workflows.
//! 2. Embedded ansible assets materialized at runtime.

use std::path::{Path, PathBuf};

use tempfile::TempDir;

use crate::adapters::ansible::runtime_assets;
use crate::domain::error::AppError;

pub struct ResolvedAnsibleDir {
    path: PathBuf,
    temp_dir: Option<TempDir>,
}

impl ResolvedAnsibleDir {
    pub fn from_path(path: PathBuf) -> Self {
        Self { path, temp_dir: None }
    }

    pub fn from_temp_dir(temp_dir: TempDir) -> Self {
        let path = temp_dir.path().to_path_buf();
        Self { path, temp_dir: Some(temp_dir) }
    }

    pub fn path(&self) -> &Path {
        &self.path
    }

    pub fn into_parts(self) -> (PathBuf, Option<TempDir>) {
        (self.path, self.temp_dir)
    }
}

/// Resolve the ansible directory containing `playbook.yml` and `roles/`.
pub fn locate_ansible_dir() -> Result<ResolvedAnsibleDir, AppError> {
    locate_ansible_dir_with(
        std::env::var("CARGO_MANIFEST_DIR").ok().map(|manifest_dir| {
            PathBuf::from(manifest_dir).join("src").join("assets").join("ansible")
        }),
        || {
            runtime_assets::materialize_embedded_ansible_dir()
                .map(ResolvedAnsibleDir::from_temp_dir)
        },
    )
}

fn locate_ansible_dir_with(
    manifest_dir: Option<PathBuf>,
    materialize_embedded_ansible_dir: impl FnOnce() -> Result<ResolvedAnsibleDir, AppError>,
) -> Result<ResolvedAnsibleDir, AppError> {
    let mut searched: Vec<PathBuf> = Vec::new();

    // 1. Prefer workspace assets during cargo-driven workflows.
    if let Some(ansible_dir) = manifest_dir {
        if runtime_assets::is_valid_ansible_dir(&ansible_dir) {
            return Ok(ResolvedAnsibleDir::from_path(ansible_dir));
        }
        searched.push(ansible_dir);
    }

    // 2. Embedded runtime assets.
    let embedded_error = match materialize_embedded_ansible_dir() {
        Ok(dir) => return Ok(dir),
        Err(err) => Some(err.to_string()),
    };

    searched.dedup();

    let candidates =
        searched.iter().map(|p| format!("  {}", p.display())).collect::<Vec<_>>().join("\n");
    let embedded_detail = embedded_error
        .as_ref()
        .map(|message| format!("\nEmbedded materialization error:\n  {message}"))
        .unwrap_or_default();

    Err(AppError::AnsibleExecution {
        message: format!(
            "ansible asset directory not found.\n\
             Searched candidates:\n{candidates}{embedded_detail}\n\
             Ensure playbook.yml and roles/ exist in one of these locations."
        ),
        exit_code: None,
    })
}

#[cfg(test)]
mod tests {
    use tempfile::TempDir;

    use super::*;

    fn create_ansible_dir(root: &std::path::Path, relative: &str) -> PathBuf {
        let dir = root.join(relative);
        std::fs::create_dir_all(dir.join("roles")).unwrap();
        std::fs::write(dir.join("playbook.yml"), "---\nroles: []\n").unwrap();
        dir
    }

    #[test]
    fn prefers_manifest_assets_over_embedded_cache() {
        let temp = TempDir::new().unwrap();
        let manifest_dir = create_ansible_dir(temp.path(), "workspace/src/assets/ansible");
        let embedded_dir = create_ansible_dir(temp.path(), "cache/ansible");

        let resolved = locate_ansible_dir_with(Some(manifest_dir.clone()), || {
            Ok(ResolvedAnsibleDir::from_path(embedded_dir.clone()))
        })
        .unwrap();

        assert_eq!(resolved.path(), manifest_dir.as_path());
    }

    #[test]
    fn uses_embedded_assets_when_manifest_assets_are_missing() {
        let temp = TempDir::new().unwrap();
        let manifest_dir = temp.path().join("workspace/src/assets/ansible");
        let embedded_dir = create_ansible_dir(temp.path(), "cache/ansible");

        let resolved = locate_ansible_dir_with(Some(manifest_dir), || {
            Ok(ResolvedAnsibleDir::from_path(embedded_dir.clone()))
        })
        .unwrap();

        assert_eq!(resolved.path(), embedded_dir.as_path());
    }
}
