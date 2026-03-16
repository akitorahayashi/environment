//! `mev` — macOS development environment provisioning CLI.
//!
//! Rust-first CLI owning command routing, validation, planning, and execution
//! orchestration. `mev-internal` is consumed as a relative dependency crate
//! for latency-sensitive internal command domains.

pub mod adapters;
pub(crate) mod app;
pub mod domain;

#[cfg(test)]
pub(crate) mod testing;

/// Entry point for the CLI.
pub use app::cli::run as cli;
