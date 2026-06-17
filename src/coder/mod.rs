//! Coder owner: interactive selection of AGENTS.md sections and deployable skills.
//!
//! mev manages intermediate entities under `~/.config/mev/` — a concatenated
//! `AGENTS.md` and a `skills/` directory — that agent tools symlink to. Selection
//! toggles the `disabled` manifest and rebuilds the intermediate entity; the final
//! symlinks created during provisioning are never touched here.

pub mod agents_build;
pub mod catalog;
pub mod manifest;
pub mod skills_build;
pub mod tui;

use std::path::PathBuf;

use crate::coder::catalog::Catalog;
use crate::coder::manifest::Selection;
use crate::config_dir;
use crate::error::AppError;
use crate::host_fs::fs::FsPort;

/// The two kinds of selectable coder configuration.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Selectable {
    Agents,
    Skills,
}

impl Selectable {
    pub fn label(self) -> &'static str {
        match self {
            Selectable::Agents => "AGENTS.md sections",
            Selectable::Skills => "skills",
        }
    }
}

/// Paths a selectable reads from and writes to, resolved from the home directory.
struct Paths {
    source_dir: PathBuf,
    manifest: PathBuf,
}

fn paths(kind: Selectable, home_dir: &std::path::Path) -> Paths {
    match kind {
        Selectable::Agents => Paths {
            source_dir: config_dir::agents_sections_source(home_dir),
            manifest: config_dir::agents_sections_manifest(home_dir),
        },
        Selectable::Skills => Paths {
            source_dir: config_dir::skills_source(home_dir),
            manifest: config_dir::skills_selection_manifest(home_dir),
        },
    }
}

fn catalog(
    kind: Selectable,
    fs: &dyn FsPort,
    source_dir: &std::path::Path,
) -> Result<Catalog, AppError> {
    match kind {
        Selectable::Agents => catalog::sections(fs, source_dir),
        Selectable::Skills => catalog::skills(fs, source_dir),
    }
}

/// One catalog entry and whether it is currently enabled, for presentation.
pub struct EntryState {
    pub name: String,
    pub enabled: bool,
}

/// Resolve the catalog and current selection into per-entry state for the TUI.
///
/// `unknown_disabled` carries skew warnings the caller surfaces to the user.
pub struct CurrentState {
    pub entries: Vec<EntryState>,
    pub unknown_disabled: Vec<String>,
}

/// Read the catalog and manifest, resolving the current enabled/disabled state.
pub fn current_state(
    kind: Selectable,
    fs: &dyn FsPort,
    home_dir: &std::path::Path,
) -> Result<CurrentState, AppError> {
    let p = paths(kind, home_dir);
    let catalog = catalog(kind, fs, &p.source_dir)?;
    let disabled = manifest::read_disabled(fs, &p.manifest)?;
    let selection = manifest::resolve(&catalog, &disabled);

    let entries = catalog
        .names()
        .iter()
        .map(|name| EntryState {
            name: name.clone(),
            enabled: selection.enabled.iter().any(|e| e == name),
        })
        .collect();

    Ok(CurrentState { entries, unknown_disabled: selection.unknown_disabled })
}

/// Disable every catalog entry and rebuild the intermediate entity to an empty state.
pub fn clear_selection(
    kind: Selectable,
    fs: &dyn FsPort,
    home_dir: &std::path::Path,
) -> Result<(), AppError> {
    let p = paths(kind, home_dir);
    let catalog = catalog(kind, fs, &p.source_dir)?;
    manifest::write_disabled(fs, &p.manifest, catalog.names())?;
    rebuild(kind, fs, home_dir, &p.source_dir, &[])
}

/// Persist a new enabled set and rebuild the intermediate entity.
///
/// `enabled_names` is the set the user chose to keep on; every catalog entry not in
/// that set becomes disabled. The manifest records the exact complement of the chosen
/// enabled set against the live catalog, so stale skew names are dropped on save.
pub fn apply_selection(
    kind: Selectable,
    fs: &dyn FsPort,
    home_dir: &std::path::Path,
    enabled_names: &[String],
) -> Result<(), AppError> {
    let p = paths(kind, home_dir);
    let catalog = catalog(kind, fs, &p.source_dir)?;

    let disabled: Vec<String> = catalog
        .names()
        .iter()
        .filter(|name| !enabled_names.iter().any(|e| e == *name))
        .cloned()
        .collect();
    manifest::write_disabled(fs, &p.manifest, &disabled)?;

    // Derive the canonical enabled set from the catalog (preserves order, excludes non-catalog names).
    let canonical_enabled: Vec<String> = catalog
        .names()
        .iter()
        .filter(|name| !disabled.iter().any(|d| d == *name))
        .cloned()
        .collect();
    rebuild(kind, fs, home_dir, &p.source_dir, &canonical_enabled)
}

/// Rebuild the intermediate entity for a selectable from the current manifest.
///
/// Used by provisioning to materialize the intermediate entity before symlinking,
/// and after each selection change.
pub fn rebuild_from_manifest(
    kind: Selectable,
    fs: &dyn FsPort,
    home_dir: &std::path::Path,
) -> Result<Selection, AppError> {
    let p = paths(kind, home_dir);
    let catalog = catalog(kind, fs, &p.source_dir)?;
    let disabled = manifest::read_disabled(fs, &p.manifest)?;
    let selection = manifest::resolve(&catalog, &disabled);
    rebuild(kind, fs, home_dir, &p.source_dir, &selection.enabled)?;
    Ok(selection)
}

fn rebuild(
    kind: Selectable,
    fs: &dyn FsPort,
    home_dir: &std::path::Path,
    source_dir: &std::path::Path,
    enabled: &[String],
) -> Result<(), AppError> {
    match kind {
        Selectable::Agents => {
            agents_build::build(fs, source_dir, enabled, &config_dir::agents_file(home_dir))
        }
        Selectable::Skills => {
            skills_build::build(fs, source_dir, enabled, &config_dir::skills_dir(home_dir))
        }
    }
}
