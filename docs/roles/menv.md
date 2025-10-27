# menv Role

The `menv` role installs the repository wrapper script that guarantees commands execute from the project root.

## Tag
- `menv`

Run with `just menv`; it is also part of `just common` right after the shell role.

## Tasks
- Ensure `~/.local/bin` exists (`mode: 0755`).
- Assert that `repo_root_path` is provided (the Just recipe passes it explicitly).
- Render `ansible/roles/menv/templates/menv.sh.j2` to `~/.local/bin/menv` with execute permissions.

The generated script exports a `set -euo pipefail` shell, changes to `{{ repo_root_path }}`, and either spawns an interactive shell or executes the provided command. See [menv Wrapper](../menv-wrapper.md) for usage details.
