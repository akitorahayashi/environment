# Internal Commands

- Hidden Typer sub-app mounted via `app.add_typer(internal_app)`
- One domain per module: `vcs.py`, `ssh.py`, `aider.py`, `shell.py`
- `app.py` is assembly-only (creates `internal_app`, registers sub-apps)
- `__init__.py` is re-export only (`internal_app`)
- Shell aliases call `menv internal ...` instead of standalone scripts
