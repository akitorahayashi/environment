//! gh CLI boundary: command execution and the procedures built on it.

mod catalog;
mod client;
mod labels;

pub use labels::{deploy as deploy_labels, reset as reset_labels};
