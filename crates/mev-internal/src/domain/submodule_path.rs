//! Git submodule path validation.

use std::path::{Component, Path};

use crate::domain::DomainError;

pub fn validate_submodule_path(path: &str) -> Result<(), DomainError> {
    let path = Path::new(path);

    let is_valid = !path.as_os_str().is_empty()
        && !path.is_absolute()
        && path.components().all(|component| matches!(component, Component::Normal(_)));

    if is_valid {
        return Ok(());
    }

    Err(DomainError::InvalidSubmodulePath(format!(
        "'{0}': must be a relative path without traversal",
        path.display()
    )))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn absolute_path_is_rejected() {
        assert!(validate_submodule_path("/absolute/path").is_err());
    }

    #[test]
    fn parent_traversal_is_rejected() {
        assert!(validate_submodule_path("../escape/path").is_err());
    }

    #[test]
    fn current_directory_is_rejected() {
        assert!(validate_submodule_path("./vendor/some-dep").is_err());
    }

    #[test]
    fn relative_path_is_accepted() {
        assert!(validate_submodule_path("vendor/some-dep").is_ok());
    }

    #[test]
    fn dotted_segment_is_accepted() {
        assert!(validate_submodule_path("vendor/some..dep").is_ok());
    }

    #[test]
    fn empty_path_is_rejected() {
        assert!(validate_submodule_path("").is_err());
    }
}
