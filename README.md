# MacOS Environment Setup

## Directory Structure

```
.
├── .github/
│   └── workflows/
├── config/
│   ├── common/
│   │   ├── apps/
│   │   ├── brew/
│   │   ├── claude/
│   │   ├── cursor/
│   │   ├── docker/
│   │   ├── gemini/
│   │   ├── git/
│   │   ├── jj/
│   │   ├── mcp/
│   │   ├── nodejs/
│   │   ├── python/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── slash/
│   │   ├── system/
│   │   └── vscode/
│   ├── mac-mini-only/
│   │   ├── apps/
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
│   │   ├── apps/
│   │   ├── brew/
│   │   ├── claude/
│   │   ├── cursor/
│   │   ├── docker/
│   │   ├── gemini/
│   │   ├── git/
│   │   ├── java/
│   │   ├── jj/
│   │   ├── mcp/
│   │   ├── nodejs-platform/
│   │   ├── nodejs-tools/
│   │   ├── python-platform/
│   │   ├── python-tools/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── slash/
│   │   ├── system/
│   │   └── vscode/
│   └── utils/
│       ├── backup-system.sh
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

- **Install common GUI applications**: `just cmn-apps` - Installs common GUI applications via Homebrew Cask.
- **Install Mac Mini-specific GUI applications**: `just mmn-apps` - Installs Mac Mini-specific GUI applications via Homebrew Cask.
- **Pull Docker images**: `just cmn-docker-images` - Pulls Docker images listed in `config/common/docker/images.txt`.

### VCS User Profile Switching

After setup, you can easily switch between personal and work configurations for Git and JJ (Jujutsu):

- **Switch to personal configuration**: `just sw-p` - Sets personal VCS user name and email.
- **Switch to work configuration**: `just sw-w` - Sets work VCS user name and email.

These commands update both Git and JJ global configurations simultaneously using the environment variables defined in `.env`.

## Implemented Features

This project uses Ansible to automate the setup of a complete development environment. The automation logic is organized into roles, each responsible for a specific component.

1.  **Homebrew Setup (`brew` role)**
    -   Installs and configures Homebrew packages using `brew bundle`.
    -   Reads the package list from the `Brewfile` located in the corresponding configuration directory (e.g., `config/common/brew/Brewfile`).

2.  **GUI Applications (`apps` role)**
    -   Installs GUI applications (casks) using `brew bundle`.
    -   Reads the cask list from the `Brewfile` located in the corresponding apps configuration directory (e.g., `config/common/apps/Brewfile`).

3.  **Shell Configuration (`shell` role)**
    -   Sets up the shell environment by creating symbolic links for `.zprofile`, `.zshrc`, and all files within the `.zsh/` directory.
    -   All shell configuration files are sourced from `config/common/shell/`.

4.  **Git & GitHub CLI Configuration (`git` role)**
    -   Installs `git` and the GitHub CLI (`gh`) via Homebrew.
    -   Copies the `.gitconfig` file to `~/.config/git/config`.
    -   Symlinks the `.gitignore_global` file to the home directory.
    -   Configures the GitHub CLI by symlinking the `ghconfig.yml` from `config/common/git/`.

5.  **JJ (Jujutsu VCS) Configuration (`jj` role)**
    -   Installs JJ (Jujutsu) via Homebrew.
    -   Copies `.jjconfig.toml` to `~/.jjconfig.toml` (highest priority configuration).
    -   Enables version control systems to work alongside Git for next-generation VCS workflows.

6.  **macOS System Settings (`system` role)**
    -   Applies system settings using the `community.general.osx_defaults` module based on the definitions in `config/common/system/system.yml`.
    -   A backup of the current system settings can be generated by running `make system-backup`. This uses the `ansible/utils/backup-system.sh` script, which leverages `yq` and `defaults read` to create a backup based on definitions in `config/common/system/definitions/`.

7.  **Ruby Environment (`ruby` role)**
    -   Installs `rbenv` to manage Ruby versions.
    -   Reads the desired Ruby version from the `.ruby-version` file in `config/common/ruby/`.
    -   Installs the specified Ruby version and sets it as the global default.
    -   Installs a specific version of the `bundler` gem.

8.  **Visual Studio Code (`vscode` role)**
    -   Installs Visual Studio Code via Homebrew Cask.
    -   Symlinks user configuration files (`settings.json`, `keybindings.json`, etc.) from `config/common/vscode/` to the appropriate VS Code directory (`~/Library/Application Support/Code/User/`).
    -   A backup of the current VSCode extensions can be generated by running `make vscode-extensions-backup`. This creates `config/common/vscode/extensions.json` with the list of installed extensions.

9.  **Cursor Environment (`cursor` role)**
    -   Installs Cursor editor via Homebrew Cask.
    -   Downloads and installs the Cursor CLI.
    -   Symlinks user configuration files (`settings.json`, `keybindings.json`) from `config/common/cursor/` to Cursor's User directory.
    -   Installs extensions listed in `config/common/cursor/extensions.json` using the `cursor --install-extension` command. Note: Many VSCode extensions are not compatible with Cursor. Manually add compatible extension IDs to this file.
    -   **Note**: `config/common/cursor/settings.json` and `keybindings.json` are symbolic links to the corresponding files in `config/common/vscode/` for shared configuration.

10. **Python Environment (`python-platform` and `python-tools` roles)**
    -   **Platform:** Installs `pyenv`, reads the target Python version from `.python-version`, installs it, and sets it as the global default.
    -   **Tools:** Installs a list of Python tools from `config/common/python/pipx-tools.txt` using `pipx install`.

11. **Java Environment (`java` role)**
    -   Installs the `temurin@21` JDK using `homebrew_cask`.

12. **Node.js Environment (`nodejs-platform` and `nodejs-tools` roles)**
    -   **Platform:** Installs `nvm`, `jq`, and `pnpm`, reads the target Node.js version from `.nvmrc`, installs it, and sets it as the default.
    -   **Tools:** Reads the `global-packages.json` file, parses the list of dependencies, and installs them globally using `pnpm install -g`. It also symlinks the `md-to-pdf-config.js` file to the home directory.

13. **Claude Code Environment (`claude` role)**
    -   Creates the `~/.claude` directory for Claude Code configuration.
    -   Symlinks configuration files (`CLAUDE.md`, `settings.json`, `mcp-servers.json`) from `config/common/claude/` to `~/.claude/`.
    -   Generates slash commands from unified configuration in `config/common/slash/`.
    -   Installs MCP servers using the Claude CLI based on the configuration in `mcp-servers.json`, using environment variables for API tokens (`GITHUB_PERSONAL_ACCESS_TOKEN`, `OBSIDIAN_API_KEY`).

14. **Gemini CLI Environment (`gemini` role)**
    -   Creates the `~/.gemini` directory for Gemini CLI configuration.
    -   Symlinks configuration files (`GEMINI.md`, `settings.json`) from `config/common/gemini/` to `~/.gemini/`.
    -   Generates slash commands from unified configuration in `config/common/slash/`.
    -   Configures MCP servers via the symlinked `settings.json` file, using environment variables for API tokens.

15. **MCP Servers Configuration (`mcp` role)**
    -   Configures Model Context Protocol (MCP) servers for enhanced AI capabilities.
    -   Sets up Context7, Serena, VOICEVOX, and other MCP servers with proper authentication.
    -   Manages server configurations and API token integration for Claude Code and Gemini CLI.

16. **Docker Environment (`docker` role)**
    -   Pulls and manages Docker images listed in `config/common/docker/images.txt`.
    -   Ensures consistent containerized development environment across machines.
    -   Provides foundation for containerized development workflows.