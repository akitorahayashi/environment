//! Bundled GitHub label catalog.

use crate::domain::DomainError;
use serde::Deserialize;

const LABELS_JSON: &str = include_str!("../assets/gh/labels.json");

#[derive(Clone, Debug, Deserialize, Eq, PartialEq)]
pub struct LabelSpec {
    pub name: String,
    pub description: String,
    pub color: String,
}

pub fn load_bundled_labels() -> Result<Vec<LabelSpec>, DomainError> {
    Ok(serde_json::from_str(LABELS_JSON)?)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn bundled_label_specs_are_valid() {
        let specs = load_bundled_labels().expect("bundled labels should parse");
        let names = specs.iter().map(|spec| spec.name.as_str()).collect::<Vec<_>>();
        assert!(names.contains(&"bugs"));
        assert!(names.contains(&"feats"));
        assert!(names.contains(&"refacts"));
        assert!(names.contains(&"tests"));
        assert!(names.contains(&"docs"));
    }
}
