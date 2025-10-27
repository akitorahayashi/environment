# menv Wrapper

The `menv` Ansible role installs a lightweight wrapper script at `~/.local/bin/menv` using the template in `ansible/roles/menv/templates/menv.sh.j2`. The script defines the absolute repository root at provisioning time and guarantees any command you run executes from that directory, regardless of where the Git checkout lives on disk.

## Why It Exists
- **Location independence:** Automation rules require that no hard-coded paths leak into day-to-day usage. The wrapper insulates shell aliases and scripts from the repository’s physical location by always `cd`-ing into `{{ repo_root_path }}` before execution.
- **Consistent environment:** Commands that assume repo-relative paths (for example, `just`, `uv`, or helper scripts under `ansible/scripts/`) work even if you invoke them from another directory.

## Usage
Launch an interactive shell rooted at the repository:
```zsh
menv
```
Run a single command without changing your current shell:
```zsh
menv just test
menv git status
menv uv run ansible-playbook -i ansible/hosts ansible/playbook.yml --tags shell
```
Because the wrapper enforces `set -euo pipefail`, failures propagate clearly. The script is re-rendered on each run of the `menv` role, so moving the repository and reapplying the automation automatically updates the `menv` path.
