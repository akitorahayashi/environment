//! Catalog of coder selectables: AGENTS.md sections and deployable skills.
//!
//! The catalog is the authority for which entries exist and, for sections, the
//! order they concatenate in. It is derived from the deployed sources under
//! `~/.config/mev/roles/coder/global/`, never hardcoded.

use std::path::{Path, PathBuf};

use serde::Deserialize;

use crate::error::AppError;
use crate::host_fs::fs::FsPort;

/// An ordered list of catalog entries by name.
pub struct Catalog {
    entries: Vec<String>,
}

impl Catalog {
    pub fn names(&self) -> &[String] {
        &self.entries
    }

    pub fn contains(&self, name: &str) -> bool {
        self.entries.iter().any(|e| e == name)
    }
}

#[derive(Deserialize)]
struct SectionCatalogFile {
    sections: Vec<String>,
}

/// Read the AGENTS.md section catalog from the deployed sources directory.
///
/// The order in `catalog.yml` is the concatenation order. A listed section
/// without a `<name>.md`, or a `<name>.md` without a listing, is an error
/// (no silent fallback).
pub fn sections(fs: &dyn FsPort, source_dir: &Path) -> Result<Catalog, AppError> {
    let catalog_path = source_dir.join("catalog.yml");
    let content = fs.read_to_string(&catalog_path).map_err(|e| {
        AppError::Config(format!(
            "failed to read AGENTS.md section catalog '{}': {e}",
            catalog_path.display()
        ))
    })?;
    let parsed: SectionCatalogFile = serde_yaml::from_str(&content).map_err(|e| {
        AppError::Config(format!(
            "invalid AGENTS.md section catalog '{}': {e}",
            catalog_path.display()
        ))
    })?;

    let listed = parsed.sections;
    let present = markdown_stems(fs, source_dir)?;

    for name in &listed {
        if !present.contains(name) {
            return Err(AppError::Config(format!(
                "section '{name}' is listed in catalog.yml but '{name}.md' is missing in {}",
                source_dir.display()
            )));
        }
    }
    for name in &present {
        if !listed.contains(name) {
            return Err(AppError::Config(format!(
                "section file '{name}.md' exists in {} but is not listed in catalog.yml",
                source_dir.display()
            )));
        }
    }

    Ok(Catalog { entries: listed })
}

/// Read the skills catalog by scanning the deployed skills source directory.
///
/// Each subdirectory is a skill. The set is sorted for stable presentation;
/// skills carry no declared order.
pub fn skills(fs: &dyn FsPort, source_dir: &Path) -> Result<Catalog, AppError> {
    if !fs.is_dir(source_dir) {
        return Err(AppError::Config(format!(
            "skills source directory is missing: {}",
            source_dir.display()
        )));
    }
    let mut entries: Vec<String> = fs
        .read_dir(source_dir)?
        .into_iter()
        .filter(|p| fs.is_dir(p))
        .filter_map(|p| file_name(&p))
        .collect();
    entries.sort();
    Ok(Catalog { entries })
}

fn markdown_stems(fs: &dyn FsPort, source_dir: &Path) -> Result<Vec<String>, AppError> {
    let mut stems = Vec::new();
    for path in fs.read_dir(source_dir)? {
        if path.extension().and_then(|e| e.to_str()) == Some("md")
            && let Some(stem) = path.file_stem().and_then(|s| s.to_str())
        {
            stems.push(stem.to_string());
        }
    }
    Ok(stems)
}

fn file_name(path: &Path) -> Option<String> {
    path.file_name().and_then(|n| n.to_str()).map(|s| s.to_string())
}

/// Resolve the deployed `<name>.md` path for an AGENTS.md section.
pub fn section_file(source_dir: &Path, name: &str) -> PathBuf {
    source_dir.join(format!("{name}.md"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::host_fs::FakeFsPort;

    fn source() -> PathBuf {
        PathBuf::from("/src/agents-sections")
    }

    fn seed_sections(fs: &FakeFsPort, catalog_yaml: &str, files: &[&str]) {
        fs.add_file(&source().join("catalog.yml"), catalog_yaml);
        for name in files {
            fs.add_file(&source().join(format!("{name}.md")), "body");
        }
    }

    #[test]
    fn sections_returns_catalog_order() {
        let fs = FakeFsPort::new();
        seed_sections(
            &fs,
            "sections:\n  - design\n  - testing\n  - safety\n",
            &["design", "testing", "safety"],
        );
        let catalog = sections(&fs, &source()).unwrap();
        assert_eq!(catalog.names(), &["design", "testing", "safety"]);
    }

    #[test]
    fn sections_errors_on_listed_without_file() {
        let fs = FakeFsPort::new();
        seed_sections(&fs, "sections:\n  - design\n  - missing\n", &["design"]);
        assert!(sections(&fs, &source()).is_err());
    }

    #[test]
    fn sections_errors_on_file_without_listing() {
        let fs = FakeFsPort::new();
        seed_sections(&fs, "sections:\n  - design\n", &["design", "stray"]);
        assert!(sections(&fs, &source()).is_err());
    }

    #[test]
    fn skills_lists_subdirectories_sorted() {
        let fs = FakeFsPort::new();
        let dir = PathBuf::from("/src/skills");
        fs.add_dir(&dir.join("toon"));
        fs.add_dir(&dir.join("effective-prompting"));
        let catalog = skills(&fs, &dir).unwrap();
        assert_eq!(catalog.names(), &["effective-prompting", "toon"]);
    }
}
