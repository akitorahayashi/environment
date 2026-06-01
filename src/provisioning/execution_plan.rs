//! Deterministic ansible execution plan construction.

use std::collections::{HashMap, HashSet};

use crate::provisioning::profile::Profile;

/// An execution plan describes the ordered sequence of ansible tags to run.
#[derive(Debug, Clone)]
pub struct ExecutionPlan {
    pub profile: Profile,
    pub cask_tokens: Vec<String>,
    pub tags: Vec<String>,
    pub verbose: bool,
}

impl ExecutionPlan {
    /// Construct a plan for a full environment creation.
    pub fn full_setup(
        profile: Profile,
        tags: Vec<String>,
        cask_requirements: &HashMap<String, Vec<String>>,
        verbose: bool,
    ) -> Self {
        let cask_tokens = required_cask_tokens(&tags, cask_requirements);
        Self { profile, cask_tokens, tags, verbose }
    }

    /// Construct a plan for a single make invocation.
    pub fn make(
        profile: Profile,
        tags: Vec<String>,
        cask_requirements: &HashMap<String, Vec<String>>,
        verbose: bool,
    ) -> Self {
        let cask_tokens = required_cask_tokens(&tags, cask_requirements);
        Self { profile, cask_tokens, tags, verbose }
    }
}

fn required_cask_tokens(
    tags: &[String],
    cask_requirements: &HashMap<String, Vec<String>>,
) -> Vec<String> {
    let mut seen = HashSet::new();
    let mut tokens = Vec::new();
    for tag in tags {
        if let Some(required_tokens) = cask_requirements.get(tag) {
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
        let plan =
            ExecutionPlan::full_setup(Profile::Macbook, test_tags.clone(), &HashMap::new(), true);
        assert_eq!(plan.profile, Profile::Macbook);
        assert!(plan.verbose);

        assert!(plan.cask_tokens.is_empty());
        assert_eq!(plan.tags, test_tags);
    }

    #[test]
    fn make_contains_provided_tags() {
        let tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::make(Profile::MacMini, tags, &HashMap::new(), false);

        assert_eq!(plan.profile, Profile::MacMini);
        assert!(!plan.verbose);
        assert!(plan.cask_tokens.is_empty());
        assert_eq!(plan.tags, vec!["tag1".to_string(), "tag2".to_string()]);
    }

    #[test]
    fn make_deduplicates_cask_tokens_in_tag_order() {
        let tags = vec!["vscode".to_string(), "co".to_string(), "zed".to_string()];
        let mut cask_requirements = HashMap::new();
        cask_requirements.insert("vscode".to_string(), vec!["visual-studio-code".to_string()]);
        cask_requirements.insert("co".to_string(), vec!["visual-studio-code".to_string()]);
        cask_requirements.insert("zed".to_string(), vec!["zed".to_string()]);

        let plan = ExecutionPlan::make(Profile::Global, tags, &cask_requirements, false);

        assert_eq!(plan.cask_tokens, vec!["visual-studio-code".to_string(), "zed".to_string()]);
    }
}
