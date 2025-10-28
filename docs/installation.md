# Installation

Follow these steps on a fresh macOS machine to bootstrap the environment managed by `menv`.

## 1. Install Prerequisites
- **Xcode Command Line Tools:** `menv` checks for them and launches the installer when missing. You can also run `xcode-select --install` ahead of time.
- **Git:** Any recent macOS already ships Git once the Xcode tools are present.
- (Optional) **Homebrew:** The bootstrap target installs Homebrew when absent, so manual installation is unnecessary.

## 2. Clone the Repository
```zsh
cd ~/workspace  # choose any location
git clone https://github.com/akitorahayashi/menv.git
cd menv
```

## 3. Run the Bootstrap Target
Execute the Makefile target that prepares the host for automation.
```zsh
make base
```
What this does:
- Installs Xcode Command Line Tools if missing.
- Copies `.env.example` to `.env` and reminds you to set identity fields.
- Installs or upgrades Homebrew, `pyenv`, Python 3.12.11, `pipx`, `uv`, and Ansible dependencies.
- Installs `just`, the task runner used throughout the project.

## 4. Configure Environment Variables
Edit the generated `.env` file to provide VCS identities and tokens.

| Variable | Purpose |
| --- | --- |
| `PERSONAL_VCS_NAME` / `PERSONAL_VCS_EMAIL` | Personal Git and JJ identity for `just sw-p`. |
| `WORK_VCS_NAME` / `WORK_VCS_EMAIL` | Work identity used by `just sw-w`. Leave blank if unused. |
| `MENV_GITHUB_PAT` | Personal access token for MCP GitHub integration. |

## 5. Apply a Machine Profile
Choose the profile that matches the hardware and let Just drive the setup.

```zsh
# For a MacBook
make macbook

# For a Mac mini
make mac-mini
```
Each target invokes `just common`, which runs all core recipes: shell configuration, VCS tooling, editors, runtimes, AI CLIs, and Homebrew packages. When invoked through the Makefile you inherit the variables exported in `.env`.

## 6. Post-Install Steps

Restart once to guarantee macOS defaults applied by the `system` role take effect.

At this point the machine is converged. Explore [Makefile Usage](./makefile-usage.md), [Just recipes](./justfile-usage.md), and the [Architecture](./architecture.md) guides for deeper details.
