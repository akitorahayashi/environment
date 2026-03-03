//! `menv-internal` — latency-sensitive internal command runtime for `menv`.
//!
//! This binary provides the `aider`, `shell`, `ssh`, and `vcs` command domains
//! invoked by `menv internal ...` through a Python dispatch boundary.

mod app;

pub use app::cli::run as cli;
