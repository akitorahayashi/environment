//! CLI contract tests for the `make` command.

use crate::harness::TestContext;
use std::os::unix::fs::PermissionsExt;

fn install_ansible_recorder(ctx: &TestContext) -> std::path::PathBuf {
    let mocks_dir = ctx.work_dir().join(".local/pipx/venvs/ansible/bin");
    std::fs::create_dir_all(&mocks_dir).unwrap();
    let ansible_path = mocks_dir.join("ansible-playbook");
    let recorder = r#"#!/bin/bash
printf '%s\n' "$*" >> "$HOME/ansible-args.log"
"#;
    std::fs::write(&ansible_path, recorder).unwrap();
    std::fs::set_permissions(&ansible_path, std::fs::Permissions::from_mode(0o755)).unwrap();
    ansible_path
}

#[test]
fn make_vscode_runs_required_cask_phase_before_configuration() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli()
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "vscode"])
        .assert()
        .success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_cask_tokens":["visual-studio-code"]"#));
    assert!(lines[0].contains("--tags brew-cask"));
    assert!(lines[1].contains("--tags vscode"));
    assert!(!lines[1].contains("brew_cask_tokens"));
}

#[test]
fn make_desktop_batches_required_casks_once() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli()
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "desktop"])
        .assert()
        .success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(
        r#""brew_cask_tokens":["visual-studio-code","antigravity-ide","zed","ghostty"]"#
    ));
    assert!(lines[0].contains("--tags brew-cask"));
    assert!(lines[1].contains("--tags vscode,antigravity-ide,zed,ghostty"));
}

#[test]
fn make_python_runs_required_formula_phase_before_configuration() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli()
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "python"])
        .assert()
        .success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_formula_tokens":["uv","pipx"]"#));
    assert!(lines[0].contains("--tags brew-formulae"));
    assert!(lines[1].contains("--tags python-platform,python-tools"));
}
