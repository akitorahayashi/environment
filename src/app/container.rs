//! Dependency wiring for the application layer.
//!
//! `DependencyContainer` wires port traits to concrete adapter implementations.
//! No command logic resides here.

use std::path::PathBuf;

use tempfile::TempDir;

use crate::adapters::ansible::executor::AnsibleAdapter;
use crate::adapters::ansible::locator::ResolvedAnsibleDir;
use crate::adapters::fs::StdFs;
use crate::adapters::git::GitCli;
use crate::adapters::identity_store::IdentityFileStore;
use crate::adapters::macos_defaults::MacosDefaultsCli;
use crate::adapters::version_source::InstallScriptVersionSource;
use crate::adapters::vscode::VscodeCli;

/// Application context wiring ports to concrete adapters.
#[allow(dead_code)]
pub struct DependencyContainer {
    ansible_dir: PathBuf,
    _ansible_temp_dir: Option<TempDir>,
    pub home_dir: PathBuf,
    pub local_config_root: PathBuf,
    pub ansible: AnsibleAdapter,
    pub identity_store: IdentityFileStore,
    pub version_source: InstallScriptVersionSource,
    pub git: GitCli,
    pub fs: StdFs,
    pub macos_defaults: MacosDefaultsCli,
    pub vscode: VscodeCli,
}

#[allow(dead_code)]
impl DependencyContainer {
    /// Construct the context from an ansible asset directory.
    pub fn new(ansible_dir: ResolvedAnsibleDir) -> Result<Self, Box<dyn std::error::Error>> {
        let home_dir =
            dirs::home_dir().ok_or_else(|| "could not resolve home directory".to_string())?;
        let local_config_root = home_dir.join(".config").join("mev").join("roles");
        let (ansible_dir, ansible_temp_dir) = ansible_dir.into_parts();

        Ok(Self {
            ansible: AnsibleAdapter::new(&ansible_dir, &local_config_root)?,
            identity_store: IdentityFileStore::new(
                home_dir.join(".config").join("mev").join("identity.json"),
            ),
            version_source: InstallScriptVersionSource,
            git: GitCli::default(),
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir,
            _ansible_temp_dir: ansible_temp_dir,
            home_dir,
            local_config_root,
        })
    }

    /// Construct a lightweight identity-only context (no ansible asset resolution needed).
    pub fn for_identity() -> Result<Self, Box<dyn std::error::Error>> {
        let home_dir =
            dirs::home_dir().ok_or_else(|| "could not resolve home directory".to_string())?;
        let local_config_root = home_dir.join(".config").join("mev").join("roles");
        Ok(Self {
            ansible: AnsibleAdapter::empty(&local_config_root),
            identity_store: IdentityFileStore::new(
                home_dir.join(".config").join("mev").join("identity.json"),
            ),
            version_source: InstallScriptVersionSource,
            git: GitCli::default(),
            fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            ansible_dir: PathBuf::new(),
            _ansible_temp_dir: None,
            home_dir,
            local_config_root,
        })
    }
}
