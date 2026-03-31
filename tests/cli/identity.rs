//! CLI contract tests for the `identity` command.

use crate::harness::TestContext;
use predicates::prelude::*;

#[test]
fn identity_show_does_not_require_ansible_assets() {
    // identity show should fail with "no identity configuration found" (config-level error),
    // not with "ansible asset directory not found" (asset resolution error).
    let ctx = TestContext::new();

    ctx.cli()
        .args(["identity", "show"])
        .assert()
        .failure()
        .stderr(
            predicate::str::contains("no identity configuration found")
                .or(predicate::str::contains("configuration error")),
        )
        .stderr(predicate::str::contains("ansible").not());
}
