//! Adapter contract tests for Jujutsu CLI.

use mev::domain::ports::jj::JjPort;

#[test]
fn jj_cli_is_available_returns_bool() {
    let jj = mev::adapters::jj::cli::JjCli;
    // May be false in CI; just verify no panic.
    let _ = jj.is_available();
}
