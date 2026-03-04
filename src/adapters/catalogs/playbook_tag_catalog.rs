//! Tag catalog loaded from playbook.yml — the single source of truth.

use std::collections::HashMap;
use std::path::PathBuf;

use crate::domain::ports::tag_catalog::TagCatalog;

pub struct PlaybookTagCatalog {
    tags_by_role: HashMap<String, Vec<String>>,
    tag_to_role: HashMap<String, String>,
}

impl PlaybookTagCatalog {
    /// Empty catalog for contexts that don't need tag resolution.
    pub fn empty() -> Self {
        Self { tags_by_role: HashMap::new(), tag_to_role: HashMap::new() }
    }

    /// Load from a playbook.yml file.
    pub fn from_file(playbook_path: &PathBuf) -> Result<Self, Box<dyn std::error::Error>> {
        let content = std::fs::read_to_string(playbook_path)?;
        let docs: Vec<serde_yaml::Value> = serde_yaml::from_str(&content)?;

        let mut tags_by_role = HashMap::new();
        let mut tag_to_role = HashMap::new();

        for doc in &docs {
            if let Some(roles) = doc.get("roles").and_then(|r| r.as_sequence()) {
                for role_entry in roles {
                    if let Some(mapping) = role_entry.as_mapping() {
                        let role_name = mapping
                            .get(serde_yaml::Value::String("role".to_string()))
                            .and_then(|v| v.as_str())
                            .map(|s| s.to_string());

                        let tags: Vec<String> =
                            match mapping.get(serde_yaml::Value::String("tags".to_string())) {
                                Some(v) if v.as_sequence().is_some() => v
                                    .as_sequence()
                                    .unwrap()
                                    .iter()
                                    .filter_map(|v| v.as_str().map(|s| s.to_string()))
                                    .collect(),
                                Some(v) if v.as_str().is_some() => {
                                    vec![v.as_str().unwrap().to_string()]
                                }
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
                            tags_by_role.insert(name, tags);
                        }
                    }
                }
            }
        }

        Ok(Self { tags_by_role, tag_to_role })
    }
}

impl TagCatalog for PlaybookTagCatalog {
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
