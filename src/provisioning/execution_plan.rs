//! Deterministic ansible execution plan construction.

use crate::provisioning::profile::Profile;

/// A normalized execution unit with the display name and ansible tags to run.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExecutionUnit {
    pub name: String,
    pub ansible_tags: Vec<String>,
}

impl ExecutionUnit {
    pub fn new(name: impl Into<String>, ansible_tags: Vec<String>) -> Self {
        Self { name: name.into(), ansible_tags }
    }

    pub fn atomic(tag: impl Into<String>) -> Self {
        let name = tag.into();
        Self { name: name.clone(), ansible_tags: vec![name] }
    }
}

/// An execution plan describes the ordered sequence of execution units to run.
#[derive(Debug, Clone)]
pub struct ExecutionPlan {
    pub profile: Profile,
    pub units: Vec<ExecutionUnit>,
    pub verbose: bool,
}

/// A layered execution plan used by create for parallel execution.
#[derive(Debug, Clone)]
pub struct LayeredExecutionPlan {
    pub profile: Profile,
    pub layers: Vec<Vec<ExecutionUnit>>,
    pub verbose: bool,
}

impl ExecutionPlan {
    /// Construct a plan for a single make invocation.
    pub fn make(profile: Profile, units: Vec<ExecutionUnit>, verbose: bool) -> Self {
        Self { profile, units, verbose }
    }

    pub fn unit_names(&self) -> Vec<String> {
        self.units.iter().map(|unit| unit.name.clone()).collect()
    }

    pub fn ansible_tags(&self) -> Vec<String> {
        self.units.iter().flat_map(|unit| unit.ansible_tags.clone()).collect()
    }
}

impl LayeredExecutionPlan {
    /// Construct a layered execution plan.
    pub fn new(profile: Profile, layers: Vec<Vec<ExecutionUnit>>, verbose: bool) -> Self {
        Self { profile, layers, verbose }
    }

    /// Construct a plan for a full environment creation.
    pub fn full_setup(profile: Profile, layers: Vec<Vec<ExecutionUnit>>, verbose: bool) -> Self {
        Self::new(profile, layers, verbose)
    }

    pub fn layer_count(&self) -> usize {
        self.layers.len()
    }

    pub fn running_units(&self) -> Vec<String> {
        self.layers.iter().flat_map(|layer| layer.iter().map(|unit| unit.name.clone())).collect()
    }

    pub fn all_units(&self) -> Vec<ExecutionUnit> {
        self.layers.iter().flat_map(|layer| layer.iter().cloned()).collect()
    }

    pub fn ansible_tags(&self) -> Vec<String> {
        self.layers
            .iter()
            .flat_map(|layer| layer.iter().flat_map(|unit| unit.ansible_tags.clone()))
            .collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn make_contains_provided_units() {
        let units = vec![ExecutionUnit::new("tag1", vec!["tag1".to_string()])];
        let plan = ExecutionPlan::make(Profile::Macbook, units.clone(), true);

        assert_eq!(plan.profile, Profile::Macbook);
        assert!(plan.verbose);
        assert_eq!(plan.units, units);
    }

    #[test]
    fn layered_full_setup_contains_layers() {
        let layers = vec![vec![ExecutionUnit::new("tag1", vec!["tag1".to_string()])]];
        let plan = LayeredExecutionPlan::full_setup(Profile::MacMini, layers.clone(), false);

        assert_eq!(plan.profile, Profile::MacMini);
        assert!(!plan.verbose);
        assert_eq!(plan.layers, layers);
    }
}
