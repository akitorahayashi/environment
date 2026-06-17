//! Selection manifest: the `disabled` exclusion list and its resolution against a catalog.
//!
//! The manifest records only what the user turned off. The catalog is the authority
//! for what exists; anything not in `disabled` is enabled. This keeps new catalog
//! entries enabled by default across mev updates instead of silently dropping them.

use std::path::Path;

use serde::{Deserialize, Serialize};

use crate::coder::catalog::Catalog;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

#[derive(Default, Deserialize, Serialize)]
struct ManifestFile {
    #[serde(default)]
    disabled: Vec<String>,
}

/// The resolution of a catalog against a disabled list.
pub struct Selection {
    /// Catalog entries that are enabled, in catalog order.
    pub enabled: Vec<String>,
    /// Catalog entries that are disabled, in catalog order.
    pub disabled: Vec<String>,
    /// Disabled names that no longer exist in the catalog (skew), to be surfaced as warnings.
    pub unknown_disabled: Vec<String>,
}

/// Read the disabled list from a manifest path. Absence or empty list means nothing disabled.
pub fn read_disabled(fs: &dyn FsPort, manifest_path: &Path) -> Result<Vec<String>, AppError> {
    if !fs.exists(manifest_path) {
        return Ok(Vec::new());
    }
    let content = fs.read_to_string(manifest_path)?;
    let parsed: ManifestFile = serde_yaml::from_str(&content).map_err(|e| {
        AppError::Config(format!("invalid selection manifest '{}': {e}", manifest_path.display()))
    })?;
    Ok(parsed.disabled)
}

/// Persist a disabled list to a manifest path, creating parent directories as needed.
pub fn write_disabled(
    fs: &dyn FsPort,
    manifest_path: &Path,
    disabled: &[String],
) -> Result<(), AppError> {
    if let Some(parent) = manifest_path.parent() {
        fs.create_dir_all(parent)?;
    }
    let file = ManifestFile { disabled: disabled.to_vec() };
    let serialized = serde_yaml::to_string(&file)
        .map_err(|e| AppError::Config(format!("failed to serialize selection manifest: {e}")))?;
    fs.write(manifest_path, serialized.as_bytes())
}

/// Resolve a catalog against a disabled list (the version-skew rule).
///
/// Catalog entries absent from `disabled` are enabled; entries present are disabled.
/// Disabled names that are not in the catalog cannot exclude anything and are reported
/// as `unknown_disabled` for the caller to surface, never silently dropped.
pub fn resolve(catalog: &Catalog, disabled: &[String]) -> Selection {
    let mut enabled = Vec::new();
    let mut disabled_in_catalog = Vec::new();
    for name in catalog.names() {
        if disabled.iter().any(|d| d == name) {
            disabled_in_catalog.push(name.clone());
        } else {
            enabled.push(name.clone());
        }
    }
    let unknown_disabled =
        disabled.iter().filter(|d| !catalog.contains(d)).cloned().collect::<Vec<_>>();
    Selection { enabled, disabled: disabled_in_catalog, unknown_disabled }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::coder::catalog;
    use crate::test_support::host_fs::FakeFsPort;
    use std::path::PathBuf;

    fn catalog_of(names: &[&str]) -> Catalog {
        let fs = FakeFsPort::new();
        let dir = PathBuf::from("/src/skills");
        for name in names {
            fs.add_dir(&dir.join(name));
        }
        catalog::skills(&fs, &dir).unwrap()
    }

    #[test]
    fn absent_manifest_disables_nothing() {
        let fs = FakeFsPort::new();
        let path = PathBuf::from("/cfg/skills-selection.yml");
        assert!(read_disabled(&fs, &path).unwrap().is_empty());
    }

    #[test]
    fn write_then_read_roundtrips_disabled() {
        let fs = FakeFsPort::new();
        let path = PathBuf::from("/cfg/skills-selection.yml");
        write_disabled(&fs, &path, &["toon".to_string()]).unwrap();
        assert_eq!(read_disabled(&fs, &path).unwrap(), vec!["toon".to_string()]);
    }

    #[test]
    fn resolve_enables_entries_absent_from_disabled() {
        let catalog = catalog_of(&["design", "testing", "safety"]);
        let selection = resolve(&catalog, &["testing".to_string()]);
        assert_eq!(selection.enabled, vec!["design".to_string(), "safety".to_string()]);
        assert_eq!(selection.disabled, vec!["testing".to_string()]);
        assert!(selection.unknown_disabled.is_empty());
    }

    #[test]
    fn resolve_reports_disabled_names_absent_from_catalog() {
        let catalog = catalog_of(&["design"]);
        let selection = resolve(&catalog, &["removed".to_string()]);
        assert_eq!(selection.enabled, vec!["design".to_string()]);
        assert_eq!(selection.unknown_disabled, vec!["removed".to_string()]);
    }

    #[test]
    fn resolve_enables_newly_added_catalog_entries() {
        // A new catalog entry not present in an older disabled list stays enabled.
        let catalog = catalog_of(&["design", "security"]);
        let selection = resolve(&catalog, &["testing".to_string()]);
        assert!(selection.enabled.contains(&"security".to_string()));
    }
}
