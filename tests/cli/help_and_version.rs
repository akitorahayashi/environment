use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn version_flag_prints_package_version() {
    let ctx = TestContext::new();

    ctx.cli()
        .arg("--version")
        .assert()
        .success()
        .stdout(predicate::str::contains(env!("CARGO_PKG_VERSION")));
}

#[test]
fn help_lists_primary_commands() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(
        predicate::str::contains("create")
            .and(predicate::str::contains("make"))
            .and(predicate::str::contains("list"))
            .and(predicate::str::contains("config"))
            .and(predicate::str::contains("switch"))
            .and(predicate::str::contains("update"))
            .and(predicate::str::contains("backup")),
    );
}

#[test]
fn help_omits_internal_command() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("internal").not());
}

#[test]
fn internal_help_lists_only_supported_subcommands() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["internal", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("git").and(predicate::str::contains("gh")));
}

#[test]
fn no_args_shows_help() {
    let ctx = TestContext::new();

    ctx.cli().assert().failure().stderr(predicate::str::contains("Usage"));
}

#[test]
fn make_help_shows_flags() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["make", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--overwrite"))
        .stdout(predicate::str::contains("--verbose"))
        .stdout(predicate::str::contains("--profile"));
}

#[test]
fn create_help_shows_flags() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["create", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("--overwrite"))
        .stdout(predicate::str::contains("--verbose"));
}

#[test]
fn backup_help_shows_target_argument() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("target"));
}

#[test]
fn backup_alias_bk_is_accepted() {
    // The alias should resolve without "unrecognized subcommand" errors.
    // It will fail due to missing ansible assets, but it should not fail
    // on subcommand resolution.
    let ctx = TestContext::new();

    ctx.cli()
        .args(["bk", "--list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));
}

#[test]
fn backup_list_shows_targets() {
    let ctx = TestContext::new();

    ctx.cli().args(["backup", "--list"]).assert().success().stdout(
        predicate::str::contains("system")
            .and(predicate::str::contains("vscode"))
            .and(predicate::str::contains("Available backup targets")),
    );
}

#[test]
fn backup_short_list_flag_shows_targets() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "-l"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));

    ctx.cli()
        .args(["backup", "--ls"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available backup targets"));
}

#[test]
fn backup_unknown_target_fails() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["backup", "nonexistent"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("is not a valid target"));
}

#[test]
fn backup_help_visible_in_main_help() {
    let ctx = TestContext::new();

    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("backup"));
}

#[test]
fn switch_help_shows_identity_argument() {
    let ctx = TestContext::new();
    ctx.cli()
        .args(["switch", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("IDENTITY"));
}

#[test]
fn switch_alias_sw_is_accepted() {
    let ctx = TestContext::new();
    ctx.cli()
        .args(["sw", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("IDENTITY"));
}

#[test]
fn switch_requires_identity_argument() {
    let ctx = TestContext::new();
    ctx.cli()
        .arg("switch")
        .assert()
        .failure()
        .stderr(predicate::str::contains("IDENTITY").or(predicate::str::contains("required")));
}

#[test]
fn switch_without_config_fails_gracefully() {
    let ctx = TestContext::new();
    ctx.cli().args(["switch", "invalid"]).assert().failure();
}

#[test]
fn switch_help_visible_in_main_help() {
    let ctx = TestContext::new();
    ctx.cli()
        .arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains("switch"))
        .stdout(predicate::str::contains("sw"));
}

#[test]
fn config_deploy_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["config", "deploy", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Deploy role configs"));
}

#[test]
fn identity_show_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["identity", "show", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Display current Git identity"));
}

#[test]
fn identity_set_help() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["identity", "set", "--help"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Set Git identity"));
}

#[test]
fn list_help_shows_description() {
    let ctx = TestContext::new();
    ctx.cli().args(["list", "--help"]).assert().success().stdout(predicate::str::contains("tag"));
}

#[test]
fn list_alias_ls_is_accepted() {
    let ctx = TestContext::new();
    ctx.cli().args(["ls", "--help"]).assert().success();
}

#[test]
fn list_visible_in_main_help() {
    let ctx = TestContext::new();
    ctx.cli().arg("--help").assert().success().stdout(predicate::str::contains("list"));
}

#[test]
fn list_shows_expected_sections() {
    let ctx = TestContext::new();

    ctx.cli()
        .args(["list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Available Tags"))
        .stdout(predicate::str::contains("Tag Groups (expanded automatically):"))
        .stdout(predicate::str::contains("Profiles:"))
        .stdout(predicate::str::contains("brew-formulae"));
}
