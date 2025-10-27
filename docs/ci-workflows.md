# CI Workflows

GitHub Actions keeps the automation reproducible by running linting, tests, and setup jobs on macOS runners. The workflows are defined under `.github/workflows/` and share a reusable base action.

## Orchestration
`ci-workflows.yml` is the entrypoint triggered on pushes to `main`, pull requests, and manual dispatches. It fans out to six reusable workflows via `uses`:
- `lint-and-test.yml`
- `setup-python.yml`
- `setup-nodejs.yml`
- `setup-runtime.yml`
- `setup-ide.yml`
- `setup-system.yml`

Each workflow runs on macOS hosts so Homebrew, Ansible, and language installers behave the same way as on developer machines.

## Base Environment
All workflows call the composite action `.github/actions/setup-base` which:
1. Installs Python 3.12 via `actions/setup-python`.
2. Copies `.env.example` to `.env` for commands that expect it.
3. Installs `just` (`extractions/setup-just@v2`).
4. Sets up `uv` with caching.
5. Runs `uv sync --frozen` to install Ansible and Python dependencies.

## Workflow Responsibilities
- **lint-and-test.yml:** Checks out the repository, installs ShellCheck, prepares the `mlx-lm` virtual environment, runs `just test`, then `just lint`.
- **setup-python.yml:** Executes the Python-focused recipes (`python-platform`, `uv`, `python-tools`, `aider`) and prepares the `mlx-lm` environment.
- **setup-nodejs.yml:** Installs Node.js via `just nodejs-platform`, global packages, AI CLIs (Claude, Gemini, Codex), and regenerates slash commands.
- **setup-runtime.yml:** Installs Ruby and Rust toolchains.
- **setup-ide.yml:** Applies VS Code and Cursor settings and installs the CodeRabbit CLI.
- **setup-system.yml:** Configures Git, GitHub CLI, JJ, shell aliases, SSH, macOS defaults, and Homebrew formulae. It also smoke-tests shell aliases by sourcing `.zshrc` and running `mk --version`.

These workflows provide confidence that each role converges independently and together. Integrate new roles by creating targeted Just recipes and reusing the base action for consistency.
