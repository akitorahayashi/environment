# MacOS Environment Setup

This project automates the setup of a consistent development environment across different Macs.

## Directory Structure

```
.
├── .claude/
├── .gemini/
├── .serena/
├── .github/
│   └── workflows/
├── config/
│   ├── common/
│   └── profiles/
│       ├── macbook/
│       └── mac-mini/
├── ansible/
│   ├── hosts
│   ├── playbook.yml
│   ├── roles/
│   └── utils/
│       ├── backup-system.sh
│       └── backup-extensions.sh
├── .env
├── .env.example
├── .gitignore
├── .mcp.json
├── AGENTS.md
├── Makefile
├── README.md
├── RULES.md
└── justfile
```

## How to Use

This project automates the setup of a consistent development environment across different Macs. Use cases include:

- **Initial Setup for New MacBook**: Quickly configure a fresh MacBook with all necessary development tools and settings.
- **Post-Clean Install Automation**: Restore your environment automatically after a clean macOS installation.
- **Unified Environment Across Macs**: Maintain consistent configurations between MacBook and Mac mini, with machine-specific customizations.

## Setup Instructions

1.  **Bootstrap Setup**

    Install Xcode Command Line Tools, Homebrew, Ansible, the `just` command runner, and create the `.env` file:
    ```sh
    make base
    ```

    This command will:
    - Install Xcode Command Line Tools if not already installed
    - Create a `.env` file from `.env.example` if it doesn't exist
    - Install Homebrew if not already installed
    - Install Ansible if not already installed
    - Install the `just` command runner

    **Important**: After running `make base`, edit the `.env` file to set your `PERSONAL_VCS_NAME`, `PERSONAL_VCS_EMAIL`, `WORK_VCS_NAME`, and `WORK_VCS_EMAIL` before proceeding to the next step.

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

These commands are recommended to be run manually once after initial setup:

- **Install Brew Casks**: `just cmn-cask`, `just mbk-cask`, `just mmn-cask` - Installs Brew Casks via Homebrew Cask (common, MacBook-specific, Mac Mini-specific).
- **Pull Docker images**: `just cmn-docker-images` - Pulls Docker images listed in `config/common/docker/images.txt`.

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
    -   Reads from profile-specific `Brewfile` (e.g., `config/profiles/mac-mini/brew/formulae/Brewfile`) or falls back to common configuration (`config/common/brew/formulae/Brewfile`, `config/common/brew/cask/Brewfile`).
    -   Conditional installation: Can install formulae-only or casks-only using tags (`--tags brew-formulae`, `--tags brew-cask`).

2.  **Shell Configuration (`shell` role)**
    -   Sets up the shell environment by creating symbolic links for `.zprofile`, `.zshrc`, and all files within the `.zsh/` directory.
    -   All shell configuration files are sourced from `config/common/shell/`.

3.  **Version Control Systems (`vcs` role)**
    -   **Git**: Installs `git` via Homebrew, copies `.gitconfig` to `~/.config/git/config`, symlinks `.gitignore_global`, and sets global excludesfile configuration.
    -   **Jujutsu (JJ)**: Installs `jj` via Homebrew, copies `config.toml` to `~/.config/jj/config.toml`, and sets up conf.d directory structure.
    -   Conditional installation: Can install git-only or jj-only using tags (`--tags vcs-git`, `--tags vcs-jj`).
    -   Enables both traditional Git and next-generation VCS workflows.

4.  **GitHub CLI Configuration (`gh` role)**
    -   Installs the GitHub CLI (`gh`) via Homebrew.
    -   Configures the GitHub CLI by symlinking the `config.yml` from `config/common/gh/` to `~/.config/gh/config.yml`.
    -   Provides access to GitHub repository management, pull request workflows, and issue tracking from the command line.

5.  **SSH Configuration (`ssh` role)**
    -   Sets up SSH environment with proper security and organization.
    -   Creates `.ssh` and `.ssh/conf.d` directories with appropriate permissions (700).
    -   Symlinks the main SSH config file from `config/common/ssh/config` to `~/.ssh/config`.
    -   Symlinks individual host-specific SSH config files from `config/common/ssh/conf.d/` to `~/.ssh/conf.d/`.
    -   Configures global SSH settings including `AddKeysToAgent yes`, `UseKeychain yes`, and `ServerAliveInterval 60`.
    -   Provides SSH key management utilities via shell functions (`ssh-gk`, `ssh-ls`, `ssh-rm`, `ssha-ls`).
    -   Implements automatic SSH agent startup and reuse in `.zprofile` for seamless authentication.

6.  **macOS System Settings (`system` role)**
    -   Applies system settings using the `community.general.osx_defaults` module based on the definitions in `config/common/system/system.yml`.
    -   A backup of the current system settings can be generated by running `make system-backup`. This uses the `ansible/utils/backup-system.sh` script, which leverages `yq` and `defaults read` to create a backup based on definitions in `config/common/system/definitions/`.

7.  **Ruby Environment (`ruby` role)**
    -   Installs `rbenv` to manage Ruby versions.
    -   Reads the desired Ruby version from the `.ruby-version` file in `config/common/runtime/ruby/`.
    -   Installs the specified Ruby version and sets it as the global default.
    -   Installs a specific version of the `bundler` gem.

8.  **Editor Configuration (`vscode` and `cursor` roles)**
    Manages the setup for VS Code and Cursor, which are now in separate, modular roles.
    -   **VS Code (`vscode` role)**: Installs Visual Studio Code, symlinks configuration files from `config/common/editor/vscode/`, and installs extensions.
    -   **Cursor (`cursor` role)**: Installs Cursor, downloads its CLI, symlinks configuration files from `config/common/editor/cursor/`, and installs extensions.
    -   **Conditional Installation**: The playbook installs both editors by default. You can target a specific one by using Ansible tags: `--tags vscode` or `--tags cursor`.

9.  **Python Runtime & Tools (`python` role)**
    -   **Platform**: Installs `pyenv`, reads the target Python version from `config/common/runtime/python/.python-version`, installs it, and sets it as the global default.
    -   **Tools**: Installs Python tools from `config/common/runtime/python/pipx-tools.txt` using `pipx install`.
    -   **Aider Integration**: Installs aider-chat via pipx using the configured Python version when enabled (`--tags python-aider`).
    -   Conditional installation: Can install platform-only, tools-only, or aider-only using tags (`--tags python-platform`, `--tags python-tools`, `--tags python-aider`).

9.  **Node.js Runtime & Tools (`nodejs` role)**
    -   **Platform**: Installs `nvm`, `jq`, and `pnpm`, reads the target Node.js version from `config/common/runtime/nodejs/.nvmrc`, installs it, and sets it as the default.
    -   **Tools**: Reads `config/common/runtime/nodejs/global-packages.json`, parses dependencies, and installs them globally using `pnpm install -g`. Symlinks `md-to-pdf-config.js` to home directory.
    -   **Claude Code Integration**: Creates `~/.claude` directory, symlinks configuration files, and generates slash commands from unified configuration when enabled (`--tags nodejs-claude`).
    -   **Gemini CLI Integration**: Creates `~/.gemini` directory, symlinks configuration files, and generates slash commands when enabled (`--tags nodejs-gemini`).
    -   Conditional installation: Each component can be installed independently using tags (`--tags nodejs-platform`, `--tags nodejs-tools`, `--tags nodejs-claude`, `--tags nodejs-gemini`).

10. **MCP Servers Configuration (`mcp` role)**
    -   Configures Model Context Protocol (MCP) servers for enhanced AI capabilities.
    -   Sets up Context7, Serena, VOICEVOX, and other MCP servers with proper authentication.
    -   Manages server configurations and API token integration for Claude Code and Gemini CLI.

11. **Docker Environment (`docker` role)**
    -   Pulls and manages Docker images listed in `config/common/docker/images.txt`.
    -   Ensures consistent containerized development environment across machines.
    -   Provides foundation for containerized development workflows.


## CI/CD Pipeline Verification Items

The following GitHub Actions workflows validate the automated setup process:

- **`ci-pipeline.yml`**: Main CI pipeline orchestrating all setup workflows
- **`setup-python.yml`**: Validates Python platform and tools setup (common, MacBook, Mac mini)
- **`setup-nodejs.yml`**: Validates Node.js platform, tools, and AI integrations (Claude, Gemini)
- **`setup-sublang.yml`**: Validates Ruby and Java environment setup
- **`setup-ide.yml`**: Validates unified editor (VS Code/Cursor) configuration and extension management
- **`setup-homebrew.yml`**: Validates Homebrew package installation across all machine types
- **`setup-alias.yml`**: Validates Git, JJ, shell, SSH, and MCP configuration with alias testing
- **`setup-system.yml`**: Validates macOS system defaults application and backup verification
