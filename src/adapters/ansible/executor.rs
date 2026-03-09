//! Ansible adapter — unified playbook execution, tag resolution, and role discovery.

use std::collections::HashMap;
use std::env;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use crate::domain::error::AppError;
use crate::domain::ports::ansible::AnsiblePort;

const ANSIBLE_PLAYBOOK_BIN_ENV: &str = "ANSIBLE_PLAYBOOK_BIN";
const PIPX_HOME_ENV: &str = "PIPX_HOME";
const PIPX_ANSIBLE_PLAYBOOK_RELATIVE_PATH: &str = "venvs/ansible/bin/ansible-playbook";

fn resolve_ansible_playbook_bin() -> Result<PathBuf, AppError> {
    if let Some(custom_bin) = env::var_os(ANSIBLE_PLAYBOOK_BIN_ENV) {
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

    let pipx_home = env::var_os(PIPX_HOME_ENV)
        .map(PathBuf::from)
        .or_else(|| env::var_os("HOME").map(|home| PathBuf::from(home).join(".local").join("pipx")))
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
        ansible_dir: PathBuf,
        local_config_root: PathBuf,
    ) -> Result<Self, Box<dyn std::error::Error>> {
        let playbook_path = ansible_dir.join("playbook.yml");
        let roles_dir = ansible_dir.join("roles");

        let (tags_by_role, tag_to_role) = load_catalog(&playbook_path)?;

        Ok(Self { ansible_dir, local_config_root, roles_dir, tags_by_role, tag_to_role })
    }

    /// Empty adapter for contexts that don't need ansible resolution.
    pub fn empty(local_config_root: PathBuf) -> Self {
        Self {
            ansible_dir: PathBuf::new(),
            local_config_root,
            roles_dir: PathBuf::new(),
            tags_by_role: HashMap::new(),
            tag_to_role: HashMap::new(),
        }
    }
}

impl AnsiblePort for AnsibleAdapter {
    fn run_playbook(&self, profile: &str, tags: &[String], verbose: bool) -> Result<(), AppError> {
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

        let ansible_playbook = resolve_ansible_playbook_bin()?;

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

    fn tags_by_role(&self) -> HashMap<String, Vec<String>> {
        self.tags_by_role.clone()
    }

    fn role_for_tag(&self, tag: &str) -> Option<String> {
        self.tag_to_role.get(tag).cloned()
    }

    fn validate_tags(&self, tags: &[String]) -> bool {
        tags.iter().all(|t| self.tag_to_role.contains_key(t))
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
