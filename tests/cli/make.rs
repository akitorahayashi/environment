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
        .args(["make", "rust-platform", "rust-tools", "shell", "--verbose"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Layer 1/2:"))
        .stdout(predicate::str::contains("Layer 2/2:"))
        .stdout(predicate::str::contains("Running: rust-platform, shell"))
        .stdout(predicate::str::contains("Running: rust-tools"))
        .stdout(predicate::str::contains("✓ Completed successfully!"));
}

#[test]
fn make_prints_ansible_output_on_failure() {
    let ctx = TestContext::new();

    let ansible_mock = r#"#!/bin/bash
echo "PLAY [nodejs-tools] *******************************************************"
echo "fatal: [localhost]: FAILED! => {\"msg\": \"boom\"}" >&2
echo "mock stdout line"
exit 2
"#;

    ctx.create_mock_command("ansible-playbook", ansible_mock);
    let ansible_path = ctx.work_dir().join("ansible-playbook");

    ctx.cli()
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "nodejs-tools"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("--- nodejs-tools stdout ---"))
        .stderr(predicate::str::contains("mock stdout line"))
        .stderr(predicate::str::contains("--- nodejs-tools stderr ---"))
        .stderr(predicate::str::contains("fatal: [localhost]: FAILED!"))
        .stderr(predicate::str::contains("ansible-playbook failed with exit code 2"));
}
