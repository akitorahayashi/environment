//! Dependency wiring for the application layer.
//!
//! `AppContext` wires port traits to concrete adapter implementations.
//! No command logic resides here.

use std::path::PathBuf;

use crate::adapters::ansible_process::executor::AnsibleProcessExecutor;
use crate::adapters::catalogs::playbook_tag_catalog::PlaybookTagCatalog;
use crate::adapters::catalogs::role_catalog_from_fs::FsRoleCatalog;
use crate::adapters::local_config::config_file_store::ConfigFileStore;
use crate::adapters::local_config::config_paths;
use crate::adapters::vcs::git_configurator::GitConfigurator;
use crate::adapters::vcs::jj_configurator::JjConfigurator;
use crate::adapters::version::cargo_pkg_version::CargoPkgVersion;

/// Application context wiring ports to concrete adapters.
#[allow(dead_code)]
pub struct AppContext {
    pub ansible_dir: PathBuf,
    pub local_config_root: PathBuf,
    pub ansible_executor: AnsibleProcessExecutor,
    pub tag_catalog: PlaybookTagCatalog,
    pub role_catalog: FsRoleCatalog,
    pub config_store: ConfigFileStore,
    pub version_source: CargoPkgVersion,
    pub git_configurator: GitConfigurator,
    pub jj_configurator: JjConfigurator,
}

#[allow(dead_code)]
impl AppContext {
    /// Construct the context from an ansible asset directory.
    pub fn new(ansible_dir: PathBuf) -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = config_paths::local_config_root()?;
        let playbook_path = ansible_dir.join("playbook.yml");
        let roles_dir = ansible_dir.join("roles");

        Ok(Self {
            ansible_executor: AnsibleProcessExecutor::new(
                ansible_dir.clone(),
                local_config_root.clone(),
            ),
            tag_catalog: PlaybookTagCatalog::from_file(&playbook_path)?,
            role_catalog: FsRoleCatalog::new(roles_dir),
            config_store: ConfigFileStore::new(config_paths::default_config_path()?),
            version_source: CargoPkgVersion,
            git_configurator: GitConfigurator,
            jj_configurator: JjConfigurator,
            ansible_dir,
            local_config_root,
        })
    }

    /// Construct a config-only context (no ansible asset resolution needed).
    pub fn for_config() -> Result<Self, Box<dyn std::error::Error>> {
        let local_config_root = config_paths::local_config_root()?;
        Ok(Self {
            ansible_executor: AnsibleProcessExecutor::new(
                PathBuf::new(),
                local_config_root.clone(),
            ),
            tag_catalog: PlaybookTagCatalog::empty(),
            role_catalog: FsRoleCatalog::new(PathBuf::new()),
            config_store: ConfigFileStore::new(config_paths::default_config_path()?),
            version_source: CargoPkgVersion,
            git_configurator: GitConfigurator,
            jj_configurator: JjConfigurator,
            ansible_dir: PathBuf::new(),
            local_config_root,
        })
    }
}
