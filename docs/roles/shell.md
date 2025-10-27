# Shell Role

The `shell` role standardizes Zsh startup files, aliases, and helper scripts, ensuring every machine sources the same automation-friendly shell environment.

## Tag
- `shell`

Invoked by `just shell` and included early in `just common`.

## Tasks
- Symlink `.zprofile` and `.zshrc` from `ansible/roles/shell/config/common/` into `$HOME`, replacing existing files (`force: true`).
- Recreate `~/.menv/alias` on every run, then mirror the repository’s alias tree by symlinking each `*.sh`/`*.zsh` file from `config/common/alias`. Nested directories (for example `llm/`, `nodejs/`, `vcs/`) are preserved.
- Symlink `ansible/scripts` to `~/.menv/scripts`, exposing Python helpers like `ssh_manager.py` and `gen_gemini_aliases.py` on the PATH.

## Configuration
- Primary dotfiles: `config/common/.zprofile`, `config/common/.zshrc`.
- Alias modules: `config/common/alias/` contains topical groups such as `llm/`, `nodejs/`, `vcs/`, and more.

Because the role always recreates the alias directory and forces symlinks, re-running it safely resets the shell to the committed state.
