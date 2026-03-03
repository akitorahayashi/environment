use assert_cmd::cargo_bin_cmd;
use predicates::prelude::*;

#[test]
fn run_without_model_env_exits_1() {
    cargo_bin_cmd!("menv-internal")
        .args(["aider", "run"])
        .env_remove("AIDER_OLLAMA_MODEL")
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("AIDER_OLLAMA_MODEL"));
}

#[test]
fn set_model_without_arg_exits_1() {
    cargo_bin_cmd!("menv-internal")
        .args(["aider", "set-model"])
        .assert()
        .failure()
        .code(1)
        .stderr(predicate::str::contains("Usage: set-model"));
}

#[test]
fn set_model_with_arg_prints_export() {
    cargo_bin_cmd!("menv-internal")
        .args(["aider", "set-model", "llama3.2"])
        .assert()
        .success()
        .stdout(predicate::str::contains("export AIDER_OLLAMA_MODEL=llama3.2"));
}

#[test]
fn unset_model_when_set_prints_unset() {
    cargo_bin_cmd!("menv-internal")
        .args(["aider", "unset-model"])
        .env("AIDER_OLLAMA_MODEL", "test-model")
        .assert()
        .success()
        .stdout(predicate::str::contains("unset AIDER_OLLAMA_MODEL"));
}

#[test]
fn unset_model_when_not_set_prints_already() {
    cargo_bin_cmd!("menv-internal")
        .args(["aider", "unset-model"])
        .env_remove("AIDER_OLLAMA_MODEL")
        .assert()
        .success()
        .stdout(predicate::str::contains("already not set"));
}
