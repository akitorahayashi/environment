# MacOS Environment Setup

## Directory Structure

```
.
├── .github/
│   └── workflows/
├── config/
│   ├── common/
│   │   ├── brew/
│   │   ├── claude/
│   │   ├── gemini/
│   │   ├── gh/
│   │   ├── git/
│   │   ├── nodejs/
│   │   ├── python/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── system-defaults/
│   │   └── vscode/
│   ├── mac-mini-only/
│   │   ├── brew/
│   │   ├── nodejs/
│   │   └── python/
│   └── macbook-only/
│       ├── brew/
│       ├── nodejs/
│       └── python/
├── ansible/
│   ├── hosts
│   ├── playbook.yml
│   ├── roles/
│   │   ├── brew/
│   │   ├── claude/
│   │   ├── gemini/
│   │   ├── cursor/
│   │   ├── git/
│   │   ├── java/
│   │   ├── nodejs-platform/
│   │   ├── nodejs-tools/
│   │   ├── python-platform/
│   │   ├── python-tools/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── system_defaults/
│   │   └── vscode/
│   └── utils/
│       ├── backup-system-defaults.sh
│       └── backup-extensions.sh
├── .gitignore
├── Makefile
├── justfile
└── README.md
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

    **Important**: After running `make base`, edit the `.env` file to set your `GIT_USERNAME` and `GIT_EMAIL` before proceeding to the next step.

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

## Implemented Features

This project uses Ansible to automate the setup of a complete development environment. The automation logic is organized into roles, each responsible for a specific component.

1.  **Homebrew Setup (`brew` role)**
    -   Installs and configures Homebrew packages using `brew bundle`.
    -   Reads the package list from the `Brewfile` located in the corresponding configuration directory (e.g., `config/common/brew/Brewfile`).

2.  **Shell Configuration (`shell` role)**
    -   Sets up the shell environment by creating symbolic links for `.zprofile`, `.zshrc`, and all files within the `.zsh/` directory.
    -   All shell configuration files are sourced from `config/common/shell/`.

3.  **Git & GitHub CLI Configuration (`git` role)**
    -   Installs `git` and the GitHub CLI (`gh`) via Homebrew.
    -   Copies the `.gitconfig` file to `~/.config/git/config`.
    -   Symlinks the `.gitignore_global` file to the home directory.
    -   Sets the `user.name` and `user.email` in the global Git configuration from environment variables (`GIT_USERNAME`, `GIT_EMAIL`).
    -   Configures the GitHub CLI by symlinking the `config.yml` from `config/common/gh/`.

4.  **macOS System Settings (`system_defaults` role)**
    -   Applies system settings using the `community.general.osx_defaults` module based on the definitions in `config/common/system-defaults/system-defaults.yml`.
    -   A backup of the current system settings can be generated using the `ansible/utils/backup-system-defaults.sh` script, which uses `yq` and `defaults read` to create a backup based on definitions in `config/common/system-defaults/backup-definitions/`.
    -   A backup of the current VSCode extensions can be generated using the `ansible/utils/backup-extensions.sh` script, which creates `config/common/vscode/extensions.json` with the list of installed extensions.

5.  **Ruby Environment (`ruby` role)**
    -   Installs `rbenv` to manage Ruby versions.
    -   Reads the desired Ruby version from the `.ruby-version` file in `config/common/ruby/`.
    -   Installs the specified Ruby version and sets it as the global default.
    -   Installs a specific version of the `bundler` gem.

6.  **Visual Studio Code (`vscode` role)**
    -   Installs Visual Studio Code via Homebrew Cask.
    -   Symlinks user configuration files (`settings.json`, `keybindings.json`, etc.) from `config/common/vscode/` to the appropriate VS Code directory (`~/Library/Application Support/Code/User/`).

7.  **Cursor Environment (`cursor` role)**
    -   Installs Cursor editor via Homebrew Cask.
    -   Downloads and installs the Cursor CLI.
    -   Symlinks user configuration files (`settings.json`, `keybindings.json`) from `config/common/vscode/` to Cursor's User directory.
    -   **Note**: Extensions are not automatically installed. Many VSCode extensions are not compatible with Cursor. Manually install compatible extensions using `cursor --install-extension <extension-id>`.

8.  **Python Environment (`python-platform` and `python-tools` roles)**
    -   **Platform:** Installs `pyenv`, reads the target Python version from `.python-version`, installs it, and sets it as the global default.
    -   **Tools:** Installs a list of Python tools from `config/common/python/pipx-tools.txt` using `pipx install`.

9.  **Java Environment (`java` role)**
    -   Installs the `temurin@21` JDK using `homebrew_cask`.

10.  **Node.js Environment (`nodejs-platform` and `nodejs-tools` roles)**
    -   **Platform:** Installs `nvm`, `jq`, and `pnpm`, reads the target Node.js version from `.nvmrc`, installs it, and sets it as the default.
    -   **Tools:** Reads the `global-packages.json` file, parses the list of dependencies, and installs them globally using `pnpm install -g`. It also symlinks the `md-to-pdf-config.js` file to the home directory.

11.  **Claude Code Environment (`claude` role)**
    -   Creates the `~/.claude` directory for Claude Code configuration.
    -   Symlinks configuration files (`CLAUDE.md`, `settings.json`, `mcp-servers.json`) from `config/common/claude/` to `~/.claude/`.
    -   Symlinks the `commands/` directory to `~/.claude/`.
    -   Installs MCP servers using the Claude CLI based on the configuration in `mcp-servers.json`, using environment variables for API tokens (`GITHUB_PERSONAL_ACCESS_TOKEN`, `OBSIDIAN_API_KEY`).

12.  **Gemini Code Environment (`gemini` role)**
    -   Creates the `~/.gemini` directory for Gemini CLI configuration.
    -   Symlinks configuration files (`GEMINI.md`, `settings.json`) from `config/common/gemini/` to `~/.gemini/`.
    -   Symlinks the `commands/` directory to `~/.gemini/`.
    -   Configures MCP servers via the symlinked `settings.json` file, using environment variables for API tokens.