//! `mev-internal` — latency-sensitive internal command runtime for `mev`.
//!
//! This crate provides the `git` and `gh` command domains
//! invoked by `mev internal ...` through the Rust CLI boundary.

mod adapters;
pub mod app;
mod domain;

pub use app::cli::run as cli;
