use assert_cmd::cargo_bin_cmd;
use predicates::prelude::*;

#[test]
fn gk_rejects_invalid_key_type() {
    cargo_bin_cmd!("menv-internal")
        .args(["ssh", "gk", "invalid-type", "example.com"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Unsupported key type"));
}

#[test]
fn gk_rejects_invalid_host() {
    cargo_bin_cmd!("menv-internal")
        .args(["ssh", "gk", "ed25519", "bad host!"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Invalid host"));
}

#[test]
fn rm_rejects_invalid_host() {
    cargo_bin_cmd!("menv-internal")
        .args(["ssh", "rm", "bad host!"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Invalid host"));
}

#[test]
fn ls_succeeds_with_no_conf_dir() {
    let dir = tempfile::tempdir().unwrap();
    cargo_bin_cmd!("menv-internal").env("HOME", dir.path()).args(["ssh", "ls"]).assert().success();
}
