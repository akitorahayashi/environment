use assert_cmd::cargo_bin_cmd;
use predicates::prelude::*;

#[test]
fn delete_submodule_rejects_absolute_path() {
    cargo_bin_cmd!("menv-internal")
        .args(["vcs", "delete-submodule", "/absolute/path"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Invalid submodule path"));
}

#[test]
fn delete_submodule_rejects_parent_traversal() {
    cargo_bin_cmd!("menv-internal")
        .args(["vcs", "delete-submodule", "../escape/path"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Invalid submodule path"));
}
