//! Deterministic ansible execution plan construction.

use crate::provisioning::profile::Profile;

/// An execution plan describes the ordered sequence of ansible tags to run.
#[derive(Debug, Clone)]
pub struct ExecutionPlan {
    pub profile: Profile,
    pub tags: Vec<String>,
    pub verbose: bool,
}

impl ExecutionPlan {
    /// Construct a plan for a full environment creation.
    pub fn full_setup(profile: Profile, tags: Vec<String>, verbose: bool) -> Self {
        Self { profile, tags, verbose }
    }

    /// Construct a plan for a single make invocation.
    pub fn make(profile: Profile, tags: Vec<String>, verbose: bool) -> Self {
        Self { profile, tags, verbose }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn full_setup_contains_all_tags() {
        let test_tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::full_setup(Profile::Macbook, test_tags.clone(), true);
        assert_eq!(plan.profile, Profile::Macbook);
        assert!(plan.verbose);

        assert_eq!(plan.tags, test_tags);
    }

    #[test]
    fn make_contains_provided_tags() {
        let tags = vec!["tag1".to_string(), "tag2".to_string()];
        let plan = ExecutionPlan::make(Profile::MacMini, tags, false);

        assert_eq!(plan.profile, Profile::MacMini);
        assert!(!plan.verbose);
        assert_eq!(plan.tags, vec!["tag1".to_string(), "tag2".to_string()]);
    }
}
