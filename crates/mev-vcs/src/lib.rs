//! `mev-vcs` — latency-sensitive version-control command runtime for `mev`.
//!
//! Exposes the `git` and `gh` tool boundaries consumed by `mev internal ...`
//! through the Rust CLI boundary. The crate owns the provisioning of git/gh
//! command procedures and exposes plain value-and-function APIs; clap parsing
//! lives in `mev`.

mod error;
mod process;

pub mod gh;
pub mod git;

pub mod testing;

pub use error::VcsError;
