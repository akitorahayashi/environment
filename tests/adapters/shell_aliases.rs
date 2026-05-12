//! Shell alias behavior tests for bundled provisioning assets.

use std::{path::Path, process::Command};

fn project_root() -> &'static Path {
    Path::new(env!("CARGO_MANIFEST_DIR"))
}

#[test]
fn run_prefix_aliases_expand_to_runnable_commands() {
    let output = Command::new("/bin/bash")
        .arg("-lc")
        .arg(
            "source src/assets/ansible/roles/shell/config/global/alias/dev/dev.sh; \
             source src/assets/ansible/roles/shell/config/global/alias/nodejs/npm.sh; \
             source src/assets/ansible/roles/shell/config/global/alias/dev/mise.sh; \
             source src/assets/ansible/roles/shell/config/global/alias/dev/make.sh; \
             alias np-r pn-r np-d ms-r mk-r",
        )
        .current_dir(project_root())
        .output()
        .expect("failed to inspect bundled shell aliases");

    assert!(
        output.status.success(),
        "alias inspection failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let aliases = String::from_utf8(output.stdout).expect("alias output must be utf-8");

    assert!(aliases.contains("alias np-r='npm run'"), "{aliases}");
    assert!(aliases.contains("alias pn-r='pnpm run'"), "{aliases}");
    assert!(aliases.contains("alias np-d='npm run dev'"), "{aliases}");
    assert!(aliases.contains("alias ms-r='mise run'"), "{aliases}");
    assert!(aliases.contains("alias mk-r='make run'"), "{aliases}");
}
