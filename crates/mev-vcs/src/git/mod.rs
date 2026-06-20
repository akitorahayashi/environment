//! git CLI boundary: command execution and the procedures built on it.

mod branches;
pub mod client;
mod clone;
pub mod repo_ref;
mod submodule;

pub use branches::delete as delete_branches;
pub use clone::clone as clone_repositories;
pub use submodule::delete as delete_submodule;
