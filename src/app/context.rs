//! Dependency wiring for application orchestration.

use std::path::PathBuf;

use tempfile::TempDir;

use crate::backup::macos_defaults_cli::MacosDefaultsCli;
use crate::backup::vscode_cli::VscodeCli;
use crate::host_fs::std_fs::StdFs;
use crate::identity::file_store::IdentityFileStore;
use crate::identity::git_cli::GitCli;
use crate::provisioning::ansible_runtime::AnsibleRuntime;
use crate::provisioning::assets::locator::ResolvedAnsibleDir;
use crate::update::install_script::InstallScriptVersionSource;

/// Application context wiring owner contracts to concrete integrations.
pub struct AppContext {
    provisioning_asset_root: PathBuf,
    _provisioning_asset_root_temp_dir: Option<TempDir>,
    pub home_dir: PathBuf,
    pub local_config_root: PathBuf,
    pub provisioning: AnsibleRuntime,
    pub identity_store: IdentityFileStore,
    pub version_source: InstallScriptVersionSource,
    pub git: GitCli,
    pub host_fs: StdFs,
    pub macos_defaults: MacosDefaultsCli,
    pub vscode: VscodeCli,
}

impl AppContext {
    /// Construct full context from a resolved provisioning assets directory.
    pub fn new(resolved_assets: ResolvedAnsibleDir) -> Result<Self, Box<dyn std::error::Error>> {
        let home_dir =
            dirs::home_dir().ok_or_else(|| "could not resolve home directory".to_string())?;
        let local_config_root = home_dir.join(".config").join("mev").join("roles");
        let (provisioning_asset_root, provisioning_asset_root_temp_dir) =
            resolved_assets.into_parts();

        Ok(Self {
            provisioning: AnsibleRuntime::new(&provisioning_asset_root, &local_config_root)?,
            identity_store: IdentityFileStore::new(
                home_dir.join(".config").join("mev").join("identity.json"),
            ),
            version_source: InstallScriptVersionSource,
            git: GitCli::default(),
            host_fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            provisioning_asset_root,
            _provisioning_asset_root_temp_dir: provisioning_asset_root_temp_dir,
            home_dir,
            local_config_root,
        })
    }

    /// Construct a lightweight identity-only context.
    pub fn for_identity() -> Result<Self, Box<dyn std::error::Error>> {
        let home_dir =
            dirs::home_dir().ok_or_else(|| "could not resolve home directory".to_string())?;
        let local_config_root = home_dir.join(".config").join("mev").join("roles");

        Ok(Self {
            provisioning: AnsibleRuntime::empty(&local_config_root),
            identity_store: IdentityFileStore::new(
                home_dir.join(".config").join("mev").join("identity.json"),
            ),
            version_source: InstallScriptVersionSource,
            git: GitCli::default(),
            host_fs: StdFs,
            macos_defaults: MacosDefaultsCli,
            vscode: VscodeCli,
            provisioning_asset_root: PathBuf::new(),
            _provisioning_asset_root_temp_dir: None,
            home_dir,
            local_config_root,
        })
    }

    pub fn provisioning_asset_root(&self) -> &std::path::Path {
        &self.provisioning_asset_root
    }
}
