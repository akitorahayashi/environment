//! git CLI boundary: command execution and the procedures built on it.

pub mod client;
pub mod repo_ref;
mod submodule;

pub use submodule::delete as delete_submodule;
