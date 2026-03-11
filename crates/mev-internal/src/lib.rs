//! `mev-internal` — latency-sensitive internal command runtime for `mev`.
//!
//! This binary provides the `shell` and `vcs` command domains
//! invoked by `mev internal ...` through the Rust CLI boundary.

pub mod app;

pub use app::cli::run as cli;
