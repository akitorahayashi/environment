//! Tag resolution and validation from catalog sources.

use std::collections::HashMap;

/// Tag groups that expand a shorthand into multiple tags.
pub fn tag_groups() -> HashMap<&'static str, Vec<&'static str>> {
    HashMap::from([
        ("rust", vec!["rust-platform", "rust-tools"]),
        ("python", vec!["python-platform", "python-tools"]),
        ("nodejs", vec!["nodejs-platform", "nodejs-tools"]),
        ("go", vec!["go-platform", "go-tools"]),
    ])
}

/// Ordered tag list for full environment setup (used by `create`).
pub const FULL_SETUP_TAGS: &[&str] = &[
    "brew-formulae",
    "ollama",
    "shell",
    "system",
    "git",
    "gh",
    "python-platform",
    "nodejs-platform",
    "ruby",
    "rust-platform",
    "go-platform",
    "python-tools",
    "uv",
    "nodejs-tools",
    "rust-tools",
    "go-tools",
    "vscode",
    "cursor",
    "coder",
    "mlx",
    "xcode",
];

/// Resolve a CLI tag argument into the concrete tags to run.
///
/// If the tag matches a group name, returns the expanded list.
/// Otherwise returns the tag as-is.
pub fn resolve_tags(tag: &str) -> Vec<String> {
    if let Some(group) = tag_groups().get(tag) {
        group.iter().map(|s| (*s).to_string()).collect()
    } else {
        vec![tag.to_string()]
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolves_group_tag() {
        let tags = resolve_tags("rust");
        assert_eq!(tags, vec!["rust-platform", "rust-tools"]);
    }

    #[test]
    fn resolves_single_tag() {
        let tags = resolve_tags("shell");
        assert_eq!(tags, vec!["shell"]);
    }
}
