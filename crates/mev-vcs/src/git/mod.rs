//! git CLI boundary: command execution and the procedures built on it.

pub mod client;
mod clone;
pub mod repo_ref;
mod submodule;

pub use clone::clone as clone_repositories;
pub use submodule::delete as delete_submodule;
