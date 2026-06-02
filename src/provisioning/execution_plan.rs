//! Deterministic ansible execution plan construction.

use std::collections::{HashMap, HashSet};

use crate::provisioning::profile::Profile;

/// An execution plan describes the ordered sequence of ansible tags to run.
#[derive(Debug, Clone)]
pub struct ExecutionPlan {
    pub profile: Profile,
    pub tap_tokens: Vec<String>,
    pub formula_tokens: Vec<String>,
    pub cask_tokens: Vec<String>,
    pub tags: Vec<String>,
    pub verbose: bool,
}

impl ExecutionPlan {
    /// Construct a plan for a full environment creation.
    pub fn full_setup(
        profile: Profile,
        tags: Vec<String>,
        tap_requirements: &HashMap<String, Vec<String>>,
        formula_requirements: &HashMap<String, Vec<String>>,
        cask_requirements: &HashMap<String, Vec<String>>,
        verbose: bool,
    ) -> Self {
        let tap_tokens = required_tokens(&tags, tap_requirements);
        let formula_tokens = required_tokens(&tags, formula_requirements);
        let cask_tokens = required_tokens(&tags, cask_requirements);
        Self { profile, tap_tokens, formula_tokens, cask_tokens, tags, verbose }
    }

    /// Construct a plan for a single make invocation.
    pub fn make(
        profile: Profile,
        tags: Vec<String>,
        tap_requirements: &HashMap<String, Vec<String>>,
        formula_requirements: &HashMap<String, Vec<String>>,
        cask_requirements: &HashMap<String, Vec<String>>,
        verbose: bool,
    ) -> Self {
        let tap_tokens = required_tokens(&tags, tap_requirements);
        let formula_tokens = required_tokens(&tags, formula_requirements);
        let cask_tokens = required_tokens(&tags, cask_requirements);
        Self { profile, tap_tokens, formula_tokens, cask_tokens, tags, verbose }
    }
}

fn required_tokens(tags: &[String], requirements: &HashMap<String, Vec<String>>) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut tokens = Vec::new();
    for tag in tags {
        if let Some(required_tokens) = requirements.get(tag) {
            for token in required_tokens {
                if seen.insert(token.clone()) {
                    tokens.push(token.clone());
                }
            }
        }
    }
    tokens
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_setup_contains_all_tags() {
        let test_tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::full_setup(
            Profile::Macbook,
            test_tags.clone(),
            &HashMap::new(),
            &HashMap::new(),
            &HashMap::new(),
            true,
        );
        assert_eq!(plan.profile, Profile::Macbook);
        assert!(plan.verbose);

        assert!(plan.tap_tokens.is_empty());
        assert!(plan.formula_tokens.is_empty());
        assert!(plan.cask_tokens.is_empty());
        assert_eq!(plan.tags, test_tags);
    }

    #[test]
    fn make_contains_provided_tags() {
        let tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::make(
            Profile::MacMini,
            tags,
            &HashMap::new(),
            &HashMap::new(),
            &HashMap::new(),
            false,
        );

        assert_eq!(plan.profile, Profile::MacMini);
        assert!(!plan.verbose);
        assert!(plan.tap_tokens.is_empty());
        assert!(plan.formula_tokens.is_empty());
        assert!(plan.cask_tokens.is_empty());
        assert_eq!(plan.tags, vec!["tag1".to_string(), "tag2".to_string()]);
    }

    #[test]
    fn make_deduplicates_brew_tokens_in_tag_order() {
        let tags = vec!["vscode".to_string(), "co".to_string(), "zed".to_string()];
        let mut tap_requirements = HashMap::new();
        tap_requirements.insert("zed".to_string(), vec!["editor/tap".to_string()]);
        let mut formula_requirements = HashMap::new();
        formula_requirements.insert("vscode".to_string(), vec!["jq".to_string()]);
        formula_requirements.insert("co".to_string(), vec!["jq".to_string()]);
        let mut cask_requirements = HashMap::new();
        cask_requirements.insert("vscode".to_string(), vec!["visual-studio-code".to_string()]);
        cask_requirements.insert("co".to_string(), vec!["visual-studio-code".to_string()]);
        cask_requirements.insert("zed".to_string(), vec!["zed".to_string()]);

        let plan = ExecutionPlan::make(
            Profile::Global,
            tags,
            &tap_requirements,
            &formula_requirements,
            &cask_requirements,
            false,
        );

        assert_eq!(plan.tap_tokens, vec!["editor/tap".to_string()]);
        assert_eq!(plan.formula_tokens, vec!["jq".to_string()]);
        assert_eq!(plan.cask_tokens, vec!["visual-studio-code".to_string(), "zed".to_string()]);
    }
}
