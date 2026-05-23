//! Tag resolution and validation from catalog sources.

use std::collections::HashMap;
use std::collections::HashSet;

use crate::error::AppError;
use crate::provisioning::execution_plan::ExecutionUnit;

/// Resolve a CLI tag argument list into normalized execution units.
///
/// Tag groups absorb any selected atomic tags they contain.
pub fn normalize_requested_tags(
    tags: &[String],
    tag_groups: &HashMap<String, Vec<String>>,
    atomic_tags: &HashSet<String>,
) -> Result<Vec<ExecutionUnit>, AppError> {
    let mut selected: Vec<ExecutionUnit> = Vec::new();

    for tag in tags {
        if let Some(group_members) = tag_groups.get(tag) {
            validate_group_members(tag, group_members, atomic_tags)?;

            if selected.iter().any(|unit| unit.name == *tag) {
                continue;
            }

            let composite_members_set: HashSet<String> = group_members.iter().cloned().collect();
            selected.retain(|unit| {
                if unit
                    .ansible_tags
                    .iter()
                    .all(|atomic_tag| composite_members_set.contains(atomic_tag))
                {
                    return false;
                }
                true
            });

            selected.push(ExecutionUnit::new(tag.clone(), group_members.clone()));
            continue;
        }

        if !atomic_tags.contains(tag) {
            return Err(AppError::InvalidTag(tag.clone()));
        }

        if selected.iter().any(|unit| unit.ansible_tags.iter().any(|atomic_tag| atomic_tag == tag))
        {
            continue;
        }

        selected.push(ExecutionUnit::new(tag.clone(), vec![tag.clone()]));
    }

    Ok(selected)
}

fn validate_group_members(
    group_name: &str,
    members: &[String],
    atomic_tags: &HashSet<String>,
) -> Result<(), AppError> {
    for member in members {
        if !atomic_tags.contains(member) {
            return Err(AppError::Config(format!(
                "tag group '{group_name}' references unknown atomic tag '{member}'"
            )));
        }
    }

    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::provisioning::execution_plan::ExecutionUnit;

    fn test_groups() -> HashMap<String, Vec<String>> {
        let mut groups = HashMap::new();
        groups.insert(
            "rust".to_string(),
            vec!["rust-platform".to_string(), "rust-tools".to_string()],
        );
        groups
    }

    fn test_atoms() -> HashSet<String> {
        ["rust-platform", "rust-tools", "shell"].into_iter().map(String::from).collect()
    }

    #[test]
    fn normalizes_group_tag() {
        let units =
            normalize_requested_tags(&["rust".to_string()], &test_groups(), &test_atoms()).unwrap();
        assert_eq!(
            units,
            vec![ExecutionUnit::new(
                "rust",
                vec!["rust-platform".to_string(), "rust-tools".to_string()]
            )]
        );
    }

    #[test]
    fn composite_absorbs_member_tags() {
        let units = normalize_requested_tags(
            &[
                "rust".to_string(),
                "rust-platform".to_string(),
                "shell".to_string(),
                "rust-tools".to_string(),
            ],
            &test_groups(),
            &test_atoms(),
        )
        .unwrap();

        assert_eq!(
            units,
            vec![
                ExecutionUnit::new(
                    "rust",
                    vec!["rust-platform".to_string(), "rust-tools".to_string()]
                ),
                ExecutionUnit::new("shell", vec!["shell".to_string()])
            ]
        );
    }

    #[test]
    fn rejects_unknown_tag() {
        let result =
            normalize_requested_tags(&["missing".to_string()], &test_groups(), &test_atoms());
        assert!(matches!(result, Err(AppError::InvalidTag(_))));
    }
}
