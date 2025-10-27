# Python Role

The `python` role delivers a reproducible Python toolchain, CLI helpers, and AI configuration.

## Tags
- `python-platform`
- `python-tools`
- `aider`
- `uv`

`just python` runs the platform and tools tags in sequence, and `just aider` / `just uv` can be invoked independently.

## Platform Tasks
- Read the version from `ansible/roles/python/config/common/.python-version`.
- Install `pyenv` via Homebrew and install the specified Python version (`pyenv install --skip-existing`).
- Set the global Python version with `pyenv global`.

## Tooling Tasks
- Load `pipx-tools.yml` and install each package (defaults include `mlx-hub` and `jupyterlab`) using `pipx install` bound to the configured pyenv Python binary.
- Ensure `~/.menv/venvs` exists, create `~/.menv/venvs/mlx-lm` with `uv venv`, and install the `mlx` dependency group via `uv sync --only-group mlx`.

## Aider Tasks
- Install `aider-chat` via `pipx` using the global Python version.
- Ensure `$HOME/.aider` exists, and symlink `.aider.conf.yml` and `.aider.model.settings.yml` from `config/common/aider/`.

## uv Tasks
- Create `$HOME/.config/uv` and symlink `uv.toml`, which sets concurrency, link mode, and resolution policy.

Together these tasks provide a stable Python environment aligned with helper tools such as Aider and mlx-lm.
