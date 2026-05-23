//! CLI contract tests for the `make` command.

use crate::harness::TestContext;
use predicates::prelude::*;
use std::os::unix::fs::PermissionsExt;

#[test]
fn make_accepts_multiple_tags_and_expands_composites() {
    let ctx = TestContext::new();

    let ansible_mock = r#"#!/bin/bash
echo "PLAY RECAP *********************************************************************"
echo "localhost                  : ok=10   changed=5    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   "
"#;

    let mocks_dir = ctx.work_dir().join(".local/pipx/venvs/ansible/bin");
    std::fs::create_dir_all(&mocks_dir).unwrap();
    let ansible_path = mocks_dir.join("ansible-playbook");

    std::fs::write(&ansible_path, ansible_mock).unwrap();
    std::fs::set_permissions(&ansible_path, std::fs::Permissions::from_mode(0o755)).unwrap();

    ctx.cli()
        .env("HOME", ctx.work_dir())
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "rust", "rust-platform", "rust-tools", "shell", "--verbose"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Running units: rust, shell"))
        .stdout(predicate::str::contains("rust => rust-platform,rust-tools"))
        .stdout(predicate::str::contains("shell => shell"));
}
