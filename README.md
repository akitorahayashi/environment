# macOS Environment Setup

This project automates the setup of a consistent development environment across different Macs.

## Directory Structure

```
.
├── .claude/
├── .codex/
├── .gemini/
├── .serena/
├── .github/
│   └── workflows/
├── ansible/
│   ├── roles/
│   ├── scripts/
│   ├── hosts
│   └── playbook.yml
├── tests/
├── .env.example
├── .gitignore
├── .mcp.json
├── Makefile
├── README.md
└── justfile
```

## How to Use

This project automates the setup of a consistent development environment across different Macs. Use cases include:

- **Initial Setup for New MacBook**: Quickly configure a fresh MacBook with all necessary development tools and settings.
- **Post-Clean Install Automation**: Restore your environment automatically after a clean macOS installation.
- **Unified Environment Across Macs**: Maintain consistent configurations between MacBook and Mac mini, with machine-specific customizations.

## Setup Instructions

Before running the numbered steps, create any directory where you want this repository to live, move into it, and unpack the tarball snapshot:

```sh
mkdir -p menv
cd menv
curl -L https://github.com/akitorahayashi/menv/tarball/main | tar xz --strip-components=1
```

1.  **Bootstrap Setup**

    Install Xcode Command Line Tools, Homebrew, Ansible, the `just` command runner, and create the `.env` file:
    ```sh
    make base
    ```

    This command will:
    - Install Xcode Command Line Tools if not already installed
    - Create a `.env` file from `.env.example` if it doesn't exist
    - Install Homebrew if not already installed
    - Install pyenv and Python 3.12 for local development
    - Install pipx and uv for Python package management
    - Install Ansible and development dependencies via uv
    - Create the `./mlx-lm` uv virtual environment and install the `mlx` dependency group
    - Install the `just` command runner

    **Important**: After running `make base`, edit the `.env` file to set your `PERSONAL_VCS_NAME`, `PERSONAL_VCS_EMAIL`, `WORK_VCS_NAME`, and `WORK_VCS_EMAIL` before proceeding to the next step.

    **Note**: CI workflows use the optimized `.github/actions/setup-base` composite action instead of `make base` for faster, cached environment setup.

2.  **Install Various Tools and Packages**

    Run one of the following commands according to your Mac.

    **For MacBook:**
    ```sh
    make macbook
    ```

    **For Mac mini:**
    ```sh
    make mac-mini
    ```
    These commands install all the necessary development tools such as Git, Ruby, Python, Node.js, and also apply macOS and shell settings. The Makefile delegates the actual setup work to `just` recipes, which now execute Ansible playbooks for improved idempotency and maintainability.

3.  **Restart macOS**

    Please restart macOS to apply all settings completely.

### Manual Execution Options

These commands are recommended to be run manually once after initial setup (Ansible collections are refreshed automatically when `just common` runs):

- **Install Brew Casks**: `just cmn-cask`, `just mbk-cask`, `just mmn-cask` - Installs Brew Casks via Homebrew Cask (common, MacBook-specific, Mac Mini-specific).
- **Pull Docker images**: `just cmn-docker-images` - Pulls Docker images listed in `ansible/roles/docker/config/common/images.txt`.

### Codex ↔ MCP Synchronization

- Run `just cmn-codex` before `just cmn-mcp` (or simply execute `just cmn-codex-mcp`) so the Codex role has already created the `~/.codex/config.toml` symlink for the MCP tasks.
- The authoritative catalogue lives in `ansible/roles/mcp/config/common/servers.json`; edits there are converted into the `[mcp_servers]` block within `ansible/roles/codex/config/common/config.toml`.
- When `~/.codex/config.toml` is missing, the synchronization block is skipped to avoid overwriting repository files.
- After catalogue changes, rerun the combined recipe and confirm the play output reports the managed block as updated once and idempotent on the subsequent run.
- Inspect the `# BEGIN MCP servers (managed by Ansible)` block in `ansible/roles/codex/config/common/config.toml` to verify the definitions match expectations while comments elsewhere remain intact.

### VCS User Profile Switching

After setup, you can easily switch between personal and work configurations for version control systems:

- **Switch to personal configuration**: `just sw-p` - Sets personal VCS user name and email.
- **Switch to work configuration**: `just sw-w` - Sets work VCS user name and email.

These commands update both Git and JJ (Jujutsu) global configurations simultaneously using the environment variables defined in `.env`. The unified VCS role manages both systems, modifying `~/.config/git/config` for Git and `~/.config/jj/config.toml` for JJ.

## Implemented Features

This project uses Ansible to automate the setup of a complete development environment. The automation logic is organized into roles, each responsible for a specific component.

1.  **Homebrew Package Management (`brew` role)**
    -   **Formulae**: Installs CLI tools using `brew bundle` with profile-specific fallback support.
    -   **Casks**: Installs GUI applications using `brew bundle` with profile-specific fallback support.
    -   Reads from profile-specific `Brewfile` (e.g., `ansible/roles/brew/config/profiles/mac-mini/formulae/Brewfile`) or falls back to common configuration (`ansible/roles/brew/config/common/formulae/Brewfile`, `ansible/roles/brew/config/common/cask/Brewfile`).
    -   Conditional installation: Can install formulae-only or casks-only using tags (`--tags brew-formulae`, `--tags brew-cask`).

2.  **Shell Configuration (`shell` role)**
    -   Sets up the shell environment by creating symbolic links for `.zprofile`, `.zshrc`, and all files within the `.zsh/` directory.
    -   All shell configuration files are sourced from `ansible/roles/shell/config/common/`.

3.  **Version Control Systems (`vcs` role)**
    -   **Git**: Installs `git` via Homebrew, copies `.gitconfig` to `~/.config/git/config`, symlinks `.gitignore_global`, and sets global excludesfile configuration.
    -   **Jujutsu (JJ)**: Installs `jj` via Homebrew, copies `config.toml` to `~/.config/jj/config.toml`, and sets up conf.d directory structure.
    -   Conditional installation: Can install git-only or jj-only using tags (`--tags git`, `--tags jj`).
    -   Enables both traditional Git and next-generation VCS workflows.

4.  **GitHub CLI Configuration (`gh` role)**
    -   Installs the GitHub CLI (`gh`) via Homebrew.
    -   Configures the GitHub CLI by symlinking the `config.yml` from `ansible/roles/gh/config/common/` to `~/.config/gh/config.yml`.
    -   Provides access to GitHub repository management, pull request workflows, and issue tracking from the command line.
    -   Ships a Python-based `gh_pr_ls.py` helper that talks directly to the GitHub API via `httpx`; export `GITHUB_TOKEN` (or `GH_TOKEN`) so the script can authenticate when listing pull requests.

5.  **SSH Configuration (`ssh` role)**
    -   Sets up SSH environment with proper security and organization.
    -   Creates `.ssh` and `.ssh/conf.d` directories with appropriate permissions (700).
    -   Symlinks the main SSH config file from `ansible/roles/ssh/config/common/config` to `~/.ssh/config`.
    -   Symlinks individual host-specific SSH config files from `ansible/roles/ssh/config/common/conf.d/` to `~/.ssh/conf.d/`.
    -   Configures global SSH settings including `AddKeysToAgent yes`, `UseKeychain yes`, and `ServerAliveInterval 60`.
    -   Provides SSH key management utilities via shell functions (`ssh-gk`, `ssh-ls`, `ssh-rm`, `ssha-ls`).
    -   Implements automatic SSH agent startup and reuse in `.zprofile` for seamless authentication.

6.  **macOS System Settings (`system` role)**
    -   Applies system settings using the `community.general.osx_defaults` module based on the definitions in `ansible/roles/system/config/common/system.yml`.
    -   A backup of the current system settings can be generated by running `make system-backup`. This uses the Python-driven `ansible/scripts/system/backup-system.py` script, which reads YAML definitions, executes `defaults read`, and renders the resulting configuration to `system.yml` without relying on external tools like `yq`.

7.  **Ruby Environment (`ruby` role)**
    -   Installs `rbenv` to manage Ruby versions.
    -   Reads the desired Ruby version from the `.ruby-version` file in `ansible/roles/ruby/config/common/`.
    -   Installs the specified Ruby version and sets it as the global default.
    -   Installs a specific version of the `bundler` gem.

8.  **Editor Configuration (`editor` role)**
    Consolidates the setup for both VS Code and Cursor into a single role with shared configuration assets.
    -   **Visual Studio Code**: Installs the application, symlinks shared configuration files from `ansible/roles/editor/config/common/`, and installs extensions listed in `vscode-extensions.json`.
    -   **Cursor**: Installs the application and CLI, symlinks the same shared configuration files, and installs extensions listed in `cursor-extensions.json`.
    -   **Conditional Installation**: The playbook installs both editors by default. You can target a specific one by using Ansible tags: `--tags vscode` or `--tags cursor`.

9.  **Python Runtime & Tools (`python` role)**
    -   **Platform**: Installs `pyenv`, reads the target Python version from `ansible/roles/python/config/common/.python-version`, installs it, and sets it as the global default.
    -   **Tools**: Installs Python tools from `ansible/roles/python/config/common/pipx-tools.txt` using `pipx install`.
    -   **Aider Integration**: Installs aider-chat via pipx using the configured Python version when enabled (`--tags python-aider`).
    -   Conditional installation: Can install platform-only, tools-only, or aider-only using tags (`--tags python-platform`, `--tags python-tools`, `--tags python-aider`).

10. **UV Package Manager Configuration (`uv` role)**
    -   Creates the `~/.config/uv` directory for uv configuration.
    -   Symlinks `uv.toml` configuration file that sets link mode to "clone" for efficient file linking on macOS, configures prerelease handling, resolution strategy, cache directory, and concurrent downloads.
    -   Provides optimized settings for the uv Python package manager.

11. **Aider AI Assistant Setup (`aider` role)**
    -   Installs aider-chat (AI coding assistant) using pipx with a specific Python version read from `.python-version` file.
    -   Creates the `~/.aider` directory and symlinks configuration files (`.aider.conf.yml`, `.aider.model.settings.yml`) for consistent AI assistant behavior.
    -   Ensures aider-chat is available with proper Python environment isolation.

12. **Node.js Runtime & Tools (`nodejs` role)**
    -   **Platform**: Installs `nvm`, `jq`, and `pnpm`, reads the target Node.js version from `ansible/roles/nodejs/config/common/.nvmrc`, installs it, and sets it as the default.
    -   **Tools**: Reads `ansible/roles/nodejs/config/common/global-packages.json`, parses dependencies, and installs them globally using `pnpm install -g`. Symlinks `md-to-pdf-config.js` to the home directory.
    -   Focused solely on runtime provisioning so CLI configuration can run independently in follow-on roles.
    -   Conditional installation: Each component can be installed independently using tags (`--tags nodejs-platform`, `--tags nodejs-tools`).

13. **Claude CLI Configuration (`claude` role)**
    -   Ensures `~/.claude` exists, symlinks prompt directories, and links Markdown/JSON assets from `ansible/roles/claude/config/common`.
    -   Links `CLAUDE.md` and prepares the `commands` directory used by Claude Code.
    -   Runs without invoking the Node.js role and can be targeted via `just cmn-claude` or `ansible-playbook --tags claude`.

14. **Gemini CLI Configuration (`gemini` role)**
    -   Creates `~/.gemini`, symlinks configuration files from `ansible/roles/gemini/config/common`, and retains templates used by the Gemini CLI.
    -   Performs a best-effort `which gemini` check, warning if the CLI is missing while still applying configuration assets.
    -   Runs independently of Node.js and can be executed with `just cmn-gemini` or `ansible-playbook --tags gemini`.

15. **Codex CLI Configuration (`codex` role)**
    -   Ensures both `~/.codex` and `~/.codex/prompts` exist and symlinks configuration from `ansible/roles/codex/config/common`.
    -   Provides prompt and agent files without re-triggering the Node.js runtime setup.
    -   Invoked through `just cmn-codex` or `ansible-playbook --tags codex`.

16. **Slash Command Generation (`slash` role)**
    -   Marks the slash generator scripts (`claude.py`, `gemini.py`, `codex.py`) as executable and runs them from the repository root.
    -   Regenerates all custom slash command assets in one pass, independent of the Node.js role.
    -   Accessible via `just cmn-slash` or `ansible-playbook --tags slash`.

17. **MCP Servers Configuration (`mcp` role)**
    -   Configures Model Context Protocol (MCP) servers for enhanced AI capabilities.
    -   Sets up Context7, Serena, VOICEVOX, and other MCP servers with proper authentication.
    -   Manages server configurations and API token integration for Claude Code and Gemini CLI.

18. **Docker Environment (`docker` role)**
    -   Pulls and manages Docker images listed in `ansible/roles/docker/config/common/images.txt`.
    -   Ensures consistent containerized development environment across machines.
    -   Provides foundation for containerized development workflows.

19. **CodeRabbit CLI (`coderabbit` role)**
    -   Installs CodeRabbit CLI for AI-powered code reviews.
    -   Downloads and executes the official installer from https://cli.coderabbit.ai/install.sh.
    -   Installs binary to `~/.local/bin/coderabbit` with alias `cr`.

## Automation Policies

This section outlines key policies that govern how automation is implemented in this project.

### Symlink Enforcement

To ensure a consistent and reliable environment, all symbolic link creation tasks are designed to be idempotent and forceful.

- **Forced Replacement**: Every symlink is created with a `force: true` flag. This means that any existing file, directory, or old symlink at the destination path will be unconditionally replaced.
- **No Existence Checks**: Automation does not check if a symlink already exists before running the creation task. This guarantees that links are always up-to-date and point to the correct source, eliminating the risk of stale or broken links.

This policy ensures that the environment's state always reflects the configuration defined in this repository.

## Tests

This project uses pytest with session-scoped fixtures for efficient validation. Run all tests with:

```sh
just test
```

### Test Coverage

**Ansible Integration (`tests/ansible/`)**
- **Justfile ↔ Playbook Tag Validation**: Ensures justfile recipes reference valid Ansible tags and roles
- **Role File Integrity**: Validates all `src:` and `lookup('file', ...)` references point to existing files

**Configuration Validation (`tests/config/`)**
- **Editor Configs**: Validates JSON syntax and schema for VS Code/Cursor configuration files
- **MCP Servers**: Verifies MCP server definitions have required fields and correct types
- **Runtime Versions**: Checks `.python-version`, `.ruby-version`, `.nvmrc` format
- **Slash Commands**: Validates configuration JSON, verifies prompt files exist, checks generator script executability
- **System Definitions**: Verifies YAML syntax and required schema for macOS system settings

All tests use properly-scoped fixtures in `conftest.py` files to share context and avoid code duplication.


## CI/CD Pipeline Verification Items

The following GitHub Actions workflows validate the automated setup process:

- **`ci-workflows.yml`**: Main CI pipeline orchestrating all setup workflows
- **`setup-python.yml`**: Validates Python platform and tools setup (common, MacBook, Mac mini)
- **`setup-nodejs.yml`**: Validates the Node.js runtime provisioning along with the Claude, Gemini, Codex, and slash configuration roles
- **`setup-sublang.yml`**: Validates Ruby and Java environment setup
- **`setup-ide.yml`**: Validates unified editor (VS Code/Cursor) configuration and extension management
- **`setup-homebrew.yml`**: Validates Homebrew package installation across all machine types
- **`setup-alias.yml`**: Validates Git, JJ, shell, SSH, and MCP configuration with alias testing
- **`setup-system.yml`**: Validates macOS system defaults application and backup verification
- **`run-tests.yml`**: Validates the slash command configuration by running tests.

### CI Environment Setup

All CI workflows use the reusable `.github/actions/setup-base` composite action for consistent base environment setup:

- **Python 3.12** with pip caching for faster builds
- **Just** command runner via `extractions/setup-just@v2`
- **Pipx** with proper PATH configuration
- **Uv** package manager with installation verification
- **Ansible dependencies** via `uv sync --frozen`
- **Proper PATH setup** for uv virtual environments

This ensures consistent tooling across all CI jobs while leveraging GitHub Actions' caching and optimization features.
