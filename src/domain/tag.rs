//! Tag resolution and validation from catalog sources.

use std::collections::HashMap;

/// Resolve a CLI tag argument into the concrete tags to run.
///
/// If the tag matches a group name, returns the expanded list.
/// Otherwise returns the tag as-is.
pub fn resolve_tags(tag: &str, tag_groups: &HashMap<String, Vec<String>>) -> Vec<String> {
    if let Some(group) = tag_groups.get(tag) { group.clone() } else { vec![tag.to_string()] }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn test_groups() -> HashMap<String, Vec<String>> {
        let mut groups = HashMap::new();
        groups.insert(
            "rust".to_string(),
            vec!["rust-platform".to_string(), "rust-tools".to_string()],
        );
        groups
    }

    #[test]
    fn resolves_group_tag() {
        let tags = resolve_tags("rust", &test_groups());
        assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
    }

    #[test]
    fn resolves_single_tag() {
        let tags = resolve_tags("shell", &test_groups());
        assert_eq!(tags, vec!["shell"]);
    }
}
