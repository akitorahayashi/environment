//! Ansible adapter — unified playbook execution, tag resolution, and role discovery.
//!
//! Testing strategy:
//! The argument formatting and binary resolution logic in `AnsibleAdapter` is extracted into
//! a separate `build_command` method to enable unit testing without triggering
//! side effects such as long-running playbook executions.

use std::collections::HashMap;
use std::env;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;

const ANSIBLE_PLAYBOOK_BIN_ENV: &str = "ANSIBLE_PLAYBOOK_BIN";
const PIPX_HOME_ENV: &str = "PIPX_HOME";
const PIPX_ANSIBLE_PLAYBOOK_RELATIVE_PATH: &str = "venvs/ansible/bin/ansible-playbook";

fn resolve_ansible_playbook_bin_with_env(
    env_var: impl Fn(&str) -> Option<std::ffi::OsString>,
) -> Result<PathBuf, AppError> {
    if let Some(custom_bin) = env_var(ANSIBLE_PLAYBOOK_BIN_ENV) {
        let custom_path = PathBuf::from(custom_bin);
        if custom_path.is_file() {
            return Ok(custom_path);
        }
        return Err(AppError::AnsibleExecution {
            message: format!(
                "{ANSIBLE_PLAYBOOK_BIN_ENV} points to a missing ansible-playbook binary: {}",
                custom_path.display()
            ),
            exit_code: None,
        });
    }

    let pipx_home = env_var(PIPX_HOME_ENV)
        .map(PathBuf::from)
        .or_else(|| env_var("HOME").map(|home| PathBuf::from(home).join(".local").join("pipx")))
        .ok_or_else(|| AppError::AnsibleExecution {
            message: format!(
                "neither {PIPX_HOME_ENV} nor HOME is set; cannot resolve pipx ansible-playbook path."
            ),
            exit_code: None,
        })?;

    let pipx_ansible_playbook = pipx_home.join(PIPX_ANSIBLE_PLAYBOOK_RELATIVE_PATH);
    if pipx_ansible_playbook.is_file() {
        return Ok(pipx_ansible_playbook);
    }

    Err(AppError::AnsibleExecution {
        message: format!(
            "ansible-playbook binary not found at '{}'. Install ansible with pipx (`pipx install ansible`) \
             or set {ANSIBLE_PLAYBOOK_BIN_ENV} explicitly.",
            pipx_ansible_playbook.display()
        ),
        exit_code: None,
    })
}

/// Unified adapter for Ansible operations.
pub struct AnsibleAdapter {
    ansible_dir: PathBuf,
    local_config_root: PathBuf,
    roles_dir: PathBuf,
    tags_by_role: HashMap<String, Vec<String>>,
    tag_to_role: HashMap<String, String>,
}

impl AnsibleAdapter {
    /// Construct from an ansible asset directory, loading the tag catalog from playbook.yml.
    pub fn new(
        ansible_dir: &Path,
        local_config_root: &Path,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let playbook_path = ansible_dir.join("playbook.yml");
        let roles_dir = ansible_dir.join("roles");

        let (tags_by_role, tag_to_role) = load_catalog(&playbook_path)?;

        Ok(Self {
            ansible_dir: ansible_dir.to_path_buf(),
            local_config_root: local_config_root.to_path_buf(),
            roles_dir,
            tags_by_role,
            tag_to_role,
        })
    }

    /// Empty adapter for contexts that don't need ansible resolution.
    pub fn empty(local_config_root: &Path) -> Self {
        Self {
            ansible_dir: PathBuf::new(),
            local_config_root: local_config_root.to_path_buf(),
            roles_dir: PathBuf::new(),
            tags_by_role: HashMap::new(),
            tag_to_role: HashMap::new(),
        }
    }

    /// Extracted command building logic to enable testing without executing playbooks.
    pub(crate) fn build_command(
        &self,
        profile: &str,
        tags: &[String],
        verbose: bool,
    ) -> Result<Command, AppError> {
        self.build_command_with_env(profile, tags, verbose, |k| env::var_os(k))
    }

    pub(crate) fn build_command_with_env(
        &self,
        profile: &str,
        tags: &[String],
        verbose: bool,
        env_var: impl Fn(&str) -> Option<std::ffi::OsString>,
    ) -> Result<Command, AppError> {
        if self.ansible_dir.as_os_str().is_empty() {
            return Err(AppError::AnsibleExecution {
                message: "ansible adapter not initialised (no ansible_dir)".to_string(),
                exit_code: None,
            });
        }

        let playbook_path = self.ansible_dir.join("playbook.yml");
        let config_path = self.ansible_dir.join("ansible.cfg");

        if !playbook_path.exists() {
            return Err(AppError::AnsibleExecution {
                message: format!("playbook not found: {}", playbook_path.display()),
                exit_code: None,
            });
        }

        if !config_path.exists() {
            return Err(AppError::AnsibleExecution {
                message: format!("ansible.cfg not found: {}", config_path.display()),
                exit_code: None,
            });
        }

        let ansible_playbook = resolve_ansible_playbook_bin_with_env(env_var)?;

        let mut cmd = Command::new(ansible_playbook);
        cmd.arg(&playbook_path)
            .arg("-e")
            .arg(format!("profile={profile}"))
            .arg("-e")
            .arg(format!("config_dir_abs_path={}", self.ansible_dir.display()))
            .arg("-e")
            .arg(format!(
                "repo_root_path={}",
                self.ansible_dir.parent().unwrap_or(Path::new(".")).display()
            ))
            .arg("-e")
            .arg(format!("local_config_root={}", self.local_config_root.display()));

        if !tags.is_empty() {
            cmd.arg("--tags").arg(tags.join(","));
        }

        if verbose {
            cmd.arg("-vvv");
        }

        cmd.env("ANSIBLE_CONFIG", &config_path);

        Ok(cmd)
    }
}

impl AnsiblePort for AnsibleAdapter {
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError> {
        let mut cmd = self.build_command(profile, tags, verbose)?;

        cmd.stdout(Stdio::inherit());
        cmd.stderr(Stdio::inherit());

        let status = cmd.status().map_err(|e| AppError::AnsibleExecution {
            message: format!("failed to run ansible-playbook: {e}"),
            exit_code: None,
        })?;

        if !status.success() {
            let code = status.code();
            return Err(AppError::AnsibleExecution {
                message: format!("ansible-playbook exited with code {}", code.unwrap_or(-1)),
                exit_code: code,
            });
        }

        Ok(())
    }

    fn roles_with_config(&self) -> Result<Vec<String>, AppError> {
        if self.roles_dir.as_os_str().is_empty() {
            return Ok(Vec::new());
        }

        let entries = std::fs::read_dir(&self.roles_dir).map_err(|e| {
            AppError::Config(format!(
                "failed to read roles directory '{}': {e}",
                self.roles_dir.display()
            ))
        })?;
        let mut roles: Vec<String> = entries
            .filter_map(|entry| {
                let path = entry.ok()?.path();
                if path.is_dir() && path.join("config").is_dir() {
                    path.file_name()?.to_str().map(String::from)
                } else {
                    None
                }
            })
            .collect();
        roles.sort();
        Ok(roles)
    }

    fn all_tags(&self) -> Vec<String> {
        let mut tags: Vec<String> = self.tag_to_role.keys().cloned().collect();
        tags.sort();
        tags
    }

    fn tags_by_role(&self) -> &HashMap<String, Vec<String>> {
        &self.tags_by_role
    }

    fn role_for_tag(&self, tag: &str) -> Option<&str> {
        self.tag_to_role.get(tag).map(|s| s.as_str())
    }

    fn validate_tags(&self, tags: &[String]) -> bool {
        tags.iter().all(|t| self.tag_to_role.contains_key(t))
    }

    fn role_config_dir(&self, role: &str) -> Option<PathBuf> {
        if self.roles_dir.as_os_str().is_empty() {
            return None;
        }

        let config_dir = self.roles_dir.join(role).join("config");
        if config_dir.is_dir() { Some(config_dir) } else { None }
    }
}

/// Tag catalog: role→tags mapping and tag→role mapping.
type Catalog = (HashMap<String, Vec<String>>, HashMap<String, String>);

/// Load tag-to-role mappings from a playbook.yml file.
fn load_catalog(playbook_path: &PathBuf) -> Result<Catalog, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string(playbook_path)?;
    let docs: Vec<serde_yaml::Value> = serde_yaml::from_str(&content)?;

    let role_key = serde_yaml::Value::String("role".to_string());
    let tags_key = serde_yaml::Value::String("tags".to_string());

    let mut tags_by_role: HashMap<String, Vec<String>> = HashMap::new();
    let mut tag_to_role = HashMap::new();

    for doc in &docs {
        if let Some(roles) = doc.get("roles").and_then(|r| r.as_sequence()) {
            for role_entry in roles {
                if let Some(mapping) = role_entry.as_mapping() {
                    let role_name =
                        mapping.get(&role_key).and_then(|v| v.as_str()).map(|s| s.to_string());

                    let tags: Vec<String> = match mapping.get(&tags_key) {
                        Some(serde_yaml::Value::Sequence(seq)) => {
                            seq.iter().filter_map(|v| v.as_str().map(|s| s.to_string())).collect()
                        }
                        Some(serde_yaml::Value::String(s)) => vec![s.clone()],
                        _ => Vec::new(),
                    };

                    if let Some(name) = role_name {
                        for tag in &tags {
                            if let Some(existing) = tag_to_role.get(tag)
                                && existing != &name
                            {
                                return Err(format!(
                                    "duplicate tag '{tag}': owned by both '{existing}' and '{name}'"
                                )
                                .into());
                            }
                            tag_to_role.insert(tag.clone(), name.clone());
                        }
                        tags_by_role.entry(name).or_default().extend(tags);
                    }
                }
            }
        }
    }

    Ok((tags_by_role, tag_to_role))
}
#[cfg(test)]
mod tests {
    use super::*;
    use std::collections::HashMap;
    use std::ffi::OsString;
    use std::fs;
    use tempfile::tempdir;

    #[test]
    fn test_resolve_ansible_playbook_bin_custom_valid() {
        let dir = tempdir().unwrap();
        let bin_path = dir.path().join("ansible-playbook");
        fs::write(&bin_path, "").unwrap();

        let mut env_map: HashMap<String, OsString> = HashMap::new();
        env_map.insert(ANSIBLE_PLAYBOOK_BIN_ENV.to_string(), bin_path.clone().into());
        let result = resolve_ansible_playbook_bin_with_env(|k| env_map.get(k).cloned());

        assert_eq!(result.unwrap(), bin_path);
    }

    #[test]
    fn test_resolve_ansible_playbook_bin_custom_invalid() {
        let mut env_map: HashMap<String, OsString> = HashMap::new();
        env_map.insert(
            ANSIBLE_PLAYBOOK_BIN_ENV.to_string(),
            OsString::from("/invalid/path/to/ansible-playbook"),
        );
        let result = resolve_ansible_playbook_bin_with_env(|k| env_map.get(k).cloned());

        assert!(matches!(result, Err(AppError::AnsibleExecution { .. })));
    }

    #[test]
    fn test_resolve_ansible_playbook_bin_pipx_home_valid() {
        let dir = tempdir().unwrap();
        let pipx_home = dir.path().join("pipx");
        let bin_dir = pipx_home.join("venvs").join("ansible").join("bin");
        fs::create_dir_all(&bin_dir).unwrap();
        let bin_path = bin_dir.join("ansible-playbook");
        fs::write(&bin_path, "").unwrap();

        let mut env_map: HashMap<String, OsString> = HashMap::new();
        env_map.insert(PIPX_HOME_ENV.to_string(), pipx_home.into());
        let result = resolve_ansible_playbook_bin_with_env(|k| env_map.get(k).cloned());

        assert_eq!(result.unwrap(), bin_path);
    }

    #[test]
    fn test_resolve_ansible_playbook_bin_home_valid() {
        let dir = tempdir().unwrap();
        let home = dir.path().join("home");
        let bin_dir = home.join(".local").join("pipx").join("venvs").join("ansible").join("bin");
        fs::create_dir_all(&bin_dir).unwrap();
        let bin_path = bin_dir.join("ansible-playbook");
        fs::write(&bin_path, "").unwrap();

        let mut env_map: HashMap<String, OsString> = HashMap::new();
        env_map.insert("HOME".to_string(), home.into());
        let result = resolve_ansible_playbook_bin_with_env(|k| env_map.get(k).cloned());

        assert_eq!(result.unwrap(), bin_path);
    }

    #[test]
    fn test_resolve_ansible_playbook_bin_not_found() {
        let env_map: HashMap<String, OsString> = HashMap::new();
        let result = resolve_ansible_playbook_bin_with_env(|k| env_map.get(k).cloned());

        assert!(matches!(result, Err(AppError::AnsibleExecution { .. })));
    }

    #[test]
    fn test_build_command_success() {
        let dir = tempdir().unwrap();
        let ansible_dir = dir.path().join("ansible");
        fs::create_dir_all(&ansible_dir).unwrap();

        let playbook_path = ansible_dir.join("playbook.yml");
        fs::write(&playbook_path, "").unwrap();

        let config_path = ansible_dir.join("ansible.cfg");
        fs::write(&config_path, "").unwrap();

        let roles_dir = ansible_dir.join("roles");
        fs::create_dir_all(&roles_dir).unwrap();

        // Mock playbook binary resolution via ANSIBLE_PLAYBOOK_BIN_ENV
        let bin_path = dir.path().join("ansible-playbook");
        fs::write(&bin_path, "").unwrap();
        let mut env_map: HashMap<String, OsString> = HashMap::new();
        env_map.insert(ANSIBLE_PLAYBOOK_BIN_ENV.to_string(), bin_path.clone().into());

        let adapter = AnsibleAdapter {
            ansible_dir,
            local_config_root: PathBuf::from("/local/config"),
            roles_dir,
            tags_by_role: HashMap::new(),
            tag_to_role: HashMap::new(),
        };

        let cmd_result = adapter.build_command_with_env(
            "my_profile",
            &["tag1".to_string(), "tag2".to_string()],
            true,
            |k| env_map.get(k).cloned(),
        );

        assert!(cmd_result.is_ok(), "build_command failed: {:?}", cmd_result.unwrap_err());
        let cmd = cmd_result.unwrap();

        let program = cmd.get_program().to_string_lossy();
        assert_eq!(program, bin_path.to_string_lossy());

        let args: Vec<String> = cmd.get_args().map(|s| s.to_string_lossy().to_string()).collect();

        assert_eq!(args[0], playbook_path.to_string_lossy());
        assert!(args.contains(&"profile=my_profile".to_string()));
        assert!(args.contains(&format!("config_dir_abs_path={}", adapter.ansible_dir.display())));
        assert!(args.contains(&format!("repo_root_path={}", dir.path().display())));
        assert!(args.contains(&"--tags".to_string()));
        assert!(args.contains(&"tag1,tag2".to_string()));
        assert!(args.contains(&"-vvv".to_string()));
        assert!(args.contains(&"local_config_root=/local/config".to_string()));
    }

    #[test]
    fn test_build_command_missing_playbook() {
        let adapter = AnsibleAdapter {
            ansible_dir: PathBuf::from("/nonexistent"),
            local_config_root: PathBuf::from("/local/config"),
            roles_dir: PathBuf::new(),
            tags_by_role: HashMap::new(),
            tag_to_role: HashMap::new(),
        };

        let result = adapter.build_command("profile", &[], false);
        assert!(matches!(result, Err(AppError::AnsibleExecution { .. })));
    }
}
