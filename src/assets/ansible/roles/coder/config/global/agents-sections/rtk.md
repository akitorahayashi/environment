## RTK

- RTK is available as the `rtk` shell command in mev-provisioned coder environments.
- AGENTS guidance uses explicit `rtk` invocation rather than assuming RTK-managed hooks or runtime patching.
- Token-optimized shell execution uses `rtk <command>` directly when reduced command output is beneficial.
- Commands that already start with `rtk` remain unchanged and are not prefixed again.
- Installation verification uses `rtk --version`; analytics and history commands are optional and are not part of provisioning checks.
