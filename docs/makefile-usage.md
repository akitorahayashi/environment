# Makefile Usage

The Makefile in the repository root provides the minimum entry points needed before Just and Ansible take over. Treat it as the bootstrap layer: it installs prerequisites, sets up Python tooling, and hands control to Just for the full configuration.

## Targets
| Target | Description |
| --- | --- |
| `make base` | Installs Xcode Command Line Tools, Homebrew, `pyenv`, Python 3.12.11, `pipx`, `uv`, Ansible dependencies, and `just`. It also copies `.env.example` to `.env` the first time. Run this once per machine. |
| `make macbook` | Invokes `just common` with the expectation that the host is a MacBook. All common roles execute, including shell, VCS, editors, runtimes, AI CLIs, and Homebrew packages. |
| `make mac-mini` | Same as `make macbook`, but intended for the Mac mini profile. Currently both call `just common`; you can extend the Justfile with profile-specific steps if needed. |
| `make system-backup` | Runs `just backup-system`, which captures the current macOS defaults into `ansible/roles/system/config/common/system.yml` using the backup script. Useful before tweaking defaults manually. |
| `make vscode-extensions-backup` | Runs `just backup-vscode-extensions` to refresh `ansible/roles/editor/config/common/vscode-extensions.json` with the extensions currently installed on the machine. |

## Workflow
1. Run `make base` on a new host. It is idempotent and safe to re-run when macOS tooling changes.
2. Edit `.env` to provide Git identities and tokens (see [Configuration](./configuration.md)).
3. Execute either `make macbook` or `make mac-mini` depending on the hardware.
4. After the initial bootstrap, daily operations move to Just recipes, described in [Justfile Usage](./justfile-usage.md).
