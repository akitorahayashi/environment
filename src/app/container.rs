//! Dependency wiring for the application layer.
//!
//! `DependencyContainer` wires port traits to concrete adapter implementations.
//! No command logic resides here.

use std::path::PathBuf;

use tempfile::TempDir;

use crate::adapters::ansible::executor::AnsibleAdapter;
use crate::adapters::ansible::locator::ResolvedAnsibleDir;
use crate::adapters::fs::std_fs::StdFs;
use crate::adapters::git::cli::GitCli;
use crate::adapters::identity_store::local_json::IdentityFileStore;
use crate::adapters::identity_store::paths;
use crate::adapters::jj::cli::JjCli;
use crate::adapters::macos_defaults::cli::MacosDefaultsCli;
use crate::adapters::version_source::install_script::InstallScriptVersionSource;
use crate::adapters::vscode::cli::VscodeCli;

/// Application context wiring ports to concrete adapters.
#[allow(dead_code)]
pub struct DependencyContainer {
    pub ansible_dir: PathBuf,
    _ansible_temp_dir: Option<TempDir>,
    pub local_config_root: PathBuf,
    pub ansible: AnsibleAdapter,
    pub identity_store: IdentityFileStore,
    pub version_source: InstallScriptVersionSource,
    pub git: GitCli,
    pub jj: JjCli,
    pub fs: StdFs,
    pub macos_defaults: MacosDefaultsCli,
    pub vscode: VscodeCli,
}

#[allow(dead_code)]
impl DependencyContainer {
    /// Construct the context from an ansible asset directory.
    pub fn new(ansible_dir: ResolvedAnsibleDir) -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = paths::local_config_root()?;
        let (ansible_dir, ansible_temp_dir) = ansible_dir.into_parts();

        Ok(Self {
            ansible: AnsibleAdapter::new(&ansible_dir, &local_config_root)?,
            identity_store: IdentityFileStore::new(paths::default_identity_path()?),
            version_source: InstallScriptVersionSource,
            git: GitCli,
            jj: JjCli,
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir,
            _ansible_temp_dir: ansible_temp_dir,
            local_config_root,
        })
    }

    /// Construct a lightweight identity-only context (no ansible asset resolution needed).
    pub fn for_identity() -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = paths::local_config_root()?;
        Ok(Self {
            ansible: AnsibleAdapter::empty(&local_config_root),
            identity_store: IdentityFileStore::new(paths::default_identity_path()?),
            version_source: InstallScriptVersionSource,
            git: GitCli,
            jj: JjCli,
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir: PathBuf::new(),
            _ansible_temp_dir: None,
            local_config_root,
        })
    }
}
