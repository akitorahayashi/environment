//! Domain rules for internal command orchestration.

pub mod error;
pub mod label_catalog;
pub mod repo_resolution;
pub mod repository_ref;
pub mod submodule_path;

pub use error::DomainError;
