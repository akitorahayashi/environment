# SSH Role

The `ssh` role maintains the OpenSSH configuration tree expected by the automation.

## Tag
- `ssh`

Called by `just ssh` and part of the default `just common` run.

## Tasks
- Ensure `$HOME/.ssh` and `$HOME/.ssh/conf.d` exist with `0700` permissions.
- Symlink the main config file from `ansible/roles/ssh/config/common/config` to `$HOME/.ssh/config`.
- Symlink every `*.conf` file from `config/common/conf.d/` into `$HOME/.ssh/conf.d/`, replacing existing entries.

## Helpers
The shell role surfaces `ansible/scripts/shell/ssh_manager.py`, which generates keys (`ssh-manager gk`), lists hosts, and removes entries. Configuration snippets created by the script land in the same `conf.d` directory managed by this role, keeping everything consistent.
