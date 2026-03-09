//! Dependency wiring for the application layer.
//!
//! `DependencyContainer` wires port traits to concrete adapter implementations.
//! No command logic resides here.

use std::path::PathBuf;

use crate::adapters::ansible::executor::AnsibleAdapter;
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
    pub fn new(ansible_dir: PathBuf) -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = paths::local_config_root()?;

        Ok(Self {
            ansible: AnsibleAdapter::new(ansible_dir.clone(), local_config_root.clone())?,
            identity_store: IdentityFileStore::new(paths::default_identity_path()?),
            version_source: InstallScriptVersionSource,
            git: GitCli,
            jj: JjCli,
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir,
            local_config_root,
        })
    }

    /// Construct a lightweight identity-only context (no ansible asset resolution needed).
    pub fn for_identity() -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = paths::local_config_root()?;
        Ok(Self {
            ansible: AnsibleAdapter::empty(local_config_root.clone()),
            identity_store: IdentityFileStore::new(paths::default_identity_path()?),
            version_source: InstallScriptVersionSource,
            git: GitCli,
            jj: JjCli,
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir: PathBuf::new(),
            local_config_root,
        })
    }
}
