//! Deterministic ansible execution plan construction.

/// An execution plan describes the ordered sequence of ansible tags to run.
#[derive(Debug, Clone)]
pub struct ExecutionPlan {
    pub profile: String,
    pub tags: Vec<String>,
    pub verbose: bool,
}

impl ExecutionPlan {
    /// Construct a plan for a full environment creation.
    pub fn full_setup(profile: &str, verbose: bool) -> Self {
        let tags = crate::domain::tag::FULL_SETUP_TAGS.iter().map(|s| (*s).to_string()).collect();
        Self { profile: profile.to_string(), tags, verbose }
    }

    /// Construct a plan for a single make invocation.
    pub fn make(profile: &str, tags: Vec<String>, verbose: bool) -> Self {
        Self { profile: profile.to_string(), tags, verbose }
    }
}
