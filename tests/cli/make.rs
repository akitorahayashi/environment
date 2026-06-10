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
fn make_agi_runs_antigravity_ide_configuration() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", "agi"]).assert().success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_cask_tokens":["antigravity-ide"]"#));
    assert!(lines[0].contains("--tags brew-cask"));
    assert!(lines[1].contains("--tags agi"));
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
    assert!(lines[0].contains(r#""brew_formula_tokens":["uv"]"#));
    assert!(lines[0].contains("--tags brew-formulae"));
    assert!(lines[1].contains("--tags python"));
}

#[test]
fn make_pipx_runs_required_formula_phase_before_configuration() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", "pipx"]).assert().success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_formula_tokens":["pipx"]"#));
    assert!(lines[0].contains("--tags brew-formulae"));
    assert!(lines[1].contains("--tags pipx"));
}

#[test]
fn make_bun_runs_bun_role_directly() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", "bun"]).assert().success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 1);
    assert!(lines[0].contains("--tags bun"));
}

#[test]
fn make_rust_and_alias_run_rust_role_directly() {
    for tag in ["rust", "rs"] {
        let ctx = TestContext::new();
        let ansible_path = install_ansible_recorder(&ctx);

        ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", tag]).assert().success();

        let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
        let lines: Vec<&str> = log.lines().collect();

        assert_eq!(lines.len(), 1);
        assert!(lines[0].contains(&format!("--tags {tag}")));
    }
}

#[test]
fn make_rust_cli_and_alias_install_gh_before_running_owner_role() {
    for tag in ["rust-cli", "rs-c"] {
        let ctx = TestContext::new();
        let ansible_path = install_ansible_recorder(&ctx);

        ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", tag]).assert().success();

        let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
        let lines: Vec<&str> = log.lines().collect();

        assert_eq!(lines.len(), 2);
        assert!(lines[0].contains(r#""brew_formula_tokens":["gh"]"#));
        assert!(lines[0].contains("--tags brew-formulae"));
        assert!(lines[1].contains(&format!("--tags {tag}")));
    }
}

#[test]
fn make_nodejs_installs_only_fnm_before_running_nodejs_role() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli()
        .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
        .args(["make", "nodejs"])
        .assert()
        .success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_formula_tokens":["fnm"]"#));
    assert!(lines[0].contains("--tags brew-formulae"));
    assert!(lines[1].contains("--tags nodejs"));
}

#[test]
fn make_pnpm_installs_pnpm_before_running_pnpm_role() {
    let ctx = TestContext::new();
    let ansible_path = install_ansible_recorder(&ctx);

    ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", "pnpm"]).assert().success();

    let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
    let lines: Vec<&str> = log.lines().collect();

    assert_eq!(lines.len(), 2);
    assert!(lines[0].contains(r#""brew_formula_tokens":["pnpm"]"#));
    assert!(lines[0].contains("--tags brew-formulae"));
    assert!(lines[1].contains("--tags pnpm"));
}

#[test]
fn make_system_installs_required_packages_before_configuration() {
    for tag in ["system", "sys"] {
        let ctx = TestContext::new();
        let ansible_path = install_ansible_recorder(&ctx);

        ctx.cli().env("ANSIBLE_PLAYBOOK_BIN", &ansible_path).args(["make", tag]).assert().success();

        let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
        let lines: Vec<&str> = log.lines().collect();

        assert_eq!(lines.len(), 3);
        assert!(lines[0].contains(r#""brew_formula_tokens":["displayplacer","duti"]"#));
        assert!(lines[0].contains("--tags brew-formulae"));
        assert!(lines[1].contains(r#""brew_cask_tokens":["zed"]"#));
        assert!(lines[1].contains("--tags brew-cask"));
        assert!(lines[2].contains(&format!("--tags {tag}")));
    }
}

#[test]
fn make_runtime_and_package_manager_aliases_target_owner_roles() {
    for (alias, formula, tag) in
        [("py", "uv", "py"), ("px", "pipx", "px"), ("nd", "fnm", "nd"), ("pn", "pnpm", "pn")]
    {
        let ctx = TestContext::new();
        let ansible_path = install_ansible_recorder(&ctx);

        ctx.cli()
            .env("ANSIBLE_PLAYBOOK_BIN", &ansible_path)
            .args(["make", alias])
            .assert()
            .success();

        let log = std::fs::read_to_string(ctx.work_dir().join("ansible-args.log")).unwrap();
        let lines: Vec<&str> = log.lines().collect();

        assert_eq!(lines.len(), 2);
        assert!(lines[0].contains(&format!(r#""brew_formula_tokens":["{formula}"]"#)));
        assert!(lines[1].contains(&format!("--tags {tag}")));
    }
}

#[test]
fn make_ollama_is_rejected_as_an_unknown_tag() {
    let ctx = TestContext::new();

    ctx.cli().args(["make", "ollama"]).assert().failure().stderr(predicates::str::contains(
        "invalid tag: 'ollama'. Use 'mev list' to see available tags.",
    ));
}
