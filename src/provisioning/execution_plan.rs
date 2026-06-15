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
    /// Brew formula installation phase tag.
    pub const FORMULA_PHASE_TAG: &str = "brew-formulae";
    /// Brew cask installation phase tag.
    pub const CASK_PHASE_TAG: &str = "brew-cask";

    /// Resolve brew token requirements for the given tags into an execution plan.
    pub fn new(
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

    /// Whether the plan runs the full brew formulae phase (all configured formulae)
    /// rather than only the tokens required by selected tags.
    pub fn runs_full_formulae(&self) -> bool {
        self.tags.iter().any(|tag| tag == Self::FORMULA_PHASE_TAG)
    }

    /// Tags to run as discrete role steps, excluding the full formula phase tag, which
    /// is dispatched separately as a brew phase rather than a role step.
    pub fn execution_tags(&self) -> Vec<String> {
        if self.runs_full_formulae() {
            self.tags.iter().filter(|tag| *tag != Self::FORMULA_PHASE_TAG).cloned().collect()
        } else {
            self.tags.clone()
        }
    }

    /// Tags whose role configs must be deployed before execution: the plan tags plus
    /// the brew phase tags implied by required tokens that are not already selected.
    pub fn config_deployment_tags(&self) -> Vec<String> {
        let mut config_tags = self.tags.clone();
        if (!self.tap_tokens.is_empty() || !self.formula_tokens.is_empty())
            && !self.runs_full_formulae()
        {
            config_tags.push(Self::FORMULA_PHASE_TAG.to_string());
        }
        if !self.cask_tokens.is_empty()
            && !config_tags.iter().any(|tag| tag == Self::CASK_PHASE_TAG)
        {
            config_tags.push(Self::CASK_PHASE_TAG.to_string());
        }
        config_tags
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
    fn preserves_profile_verbose_and_tags() {
        let test_tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::new(
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
    fn deduplicates_brew_tokens_in_tag_order() {
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

        let plan = ExecutionPlan::new(
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

    fn plan_with_tags(tags: Vec<String>) -> ExecutionPlan {
        ExecutionPlan::new(
            Profile::Global,
            tags,
            &HashMap::new(),
            &HashMap::new(),
            &HashMap::new(),
            false,
        )
    }

    #[test]
    fn runs_full_formulae_detects_formula_phase_tag() {
        let with =
            plan_with_tags(vec!["zsh".to_string(), ExecutionPlan::FORMULA_PHASE_TAG.to_string()]);
        assert!(with.runs_full_formulae());

        let without = plan_with_tags(vec!["zsh".to_string()]);
        assert!(!without.runs_full_formulae());
    }

    #[test]
    fn execution_tags_excludes_formula_phase_tag_when_present() {
        let plan = plan_with_tags(vec![
            "zsh".to_string(),
            ExecutionPlan::FORMULA_PHASE_TAG.to_string(),
            "git".to_string(),
        ]);
        assert_eq!(plan.execution_tags(), vec!["zsh".to_string(), "git".to_string()]);
    }

    #[test]
    fn execution_tags_returns_all_tags_without_formula_phase() {
        let tags = vec!["zsh".to_string(), "git".to_string()];
        let plan = plan_with_tags(tags.clone());
        assert_eq!(plan.execution_tags(), tags);
    }

    #[test]
    fn config_deployment_tags_appends_formula_phase_for_required_formulae() {
        let mut formula_requirements = HashMap::new();
        formula_requirements.insert("co".to_string(), vec!["jq".to_string()]);
        let plan = ExecutionPlan::new(
            Profile::Global,
            vec!["co".to_string()],
            &HashMap::new(),
            &formula_requirements,
            &HashMap::new(),
            false,
        );
        assert_eq!(
            plan.config_deployment_tags(),
            vec!["co".to_string(), ExecutionPlan::FORMULA_PHASE_TAG.to_string()]
        );
    }

    #[test]
    fn config_deployment_tags_appends_cask_phase_for_required_casks() {
        let mut cask_requirements = HashMap::new();
        cask_requirements.insert("vscode".to_string(), vec!["visual-studio-code".to_string()]);
        let plan = ExecutionPlan::new(
            Profile::Global,
            vec!["vscode".to_string()],
            &HashMap::new(),
            &HashMap::new(),
            &cask_requirements,
            false,
        );
        assert_eq!(
            plan.config_deployment_tags(),
            vec!["vscode".to_string(), ExecutionPlan::CASK_PHASE_TAG.to_string()]
        );
    }

    #[test]
    fn config_deployment_tags_skips_formula_phase_when_full_formulae_runs() {
        let mut formula_requirements = HashMap::new();
        formula_requirements.insert("co".to_string(), vec!["jq".to_string()]);
        let plan = ExecutionPlan::new(
            Profile::Global,
            vec!["co".to_string(), ExecutionPlan::FORMULA_PHASE_TAG.to_string()],
            &HashMap::new(),
            &formula_requirements,
            &HashMap::new(),
            false,
        );
        assert_eq!(
            plan.config_deployment_tags(),
            vec!["co".to_string(), ExecutionPlan::FORMULA_PHASE_TAG.to_string()]
        );
    }
}
