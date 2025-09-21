# MacOS Environment Setup

## Directory Structure

```
.
├── .github/
│   └── workflows/
├── config/
│   ├── common/
│   │   ├── brew/
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
│   │   ├── cursor/
│   │   ├── git/
│   │   ├── java/
│   │   ├── nodejs/
│   │   ├── python/
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

This project uses a two-step approach:
1. **Bootstrap Setup**: Use `make` to install Homebrew, Ansible, and the `just` command runner
2. **Full Setup**: Use `make` to delegate to `just` for the actual environment setup, which now runs Ansible playbooks

### Bootstrap Commands

- **`make` or `make help`**: Displays all available commands and their descriptions.
- **`make setup`**: Installs Homebrew, Ansible, and the `just` command runner (required first step).

### Full Setup Commands

- **`make macbook`**: Runs the full setup for MacBook (requires `make setup` first).
- **`make mac-mini`**: Runs the full setup for Mac mini (requires `make setup` first).

### Running Individual Tasks with Just

After running `make setup`, you can use `just` directly for individual tasks:

- **`just help`**: Shows all available just recipes
- **Common Tasks**: Run specific tasks like `just cmn-git`, `just cmn-shell`, `just cmn-java`, etc.
- **Machine-Specific Tasks**: Run machine-specific tasks like `just mbk-brew-specific`, `just mmn-brew-specific`, etc.

## Setup Instructions

1.  **Install Xcode Command Line Tools**

    ```sh
    xcode-select --install
    ```

2.  **Bootstrap Setup**

    Install Homebrew, Ansible, the `just` command runner, and create the `.env` file:
    ```sh
    make setup
    ```

    This command will:
    - Create a `.env` file from `.env.example` if it doesn't exist
    - Install Homebrew if not already installed
    - Install Ansible if not already installed
    - Install the `just` command runner

    **Important**: After running `make setup`, edit the `.env` file to set your `GIT_USERNAME` and `GIT_EMAIL` before proceeding to the next step.

3.  **Install Various Tools and Packages**

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

4.  **Restart macOS**

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
    -   Symlinks user configuration files from `config/common/vscode/` to Cursor's User directory (`~/Library/Application Support/Cursor/User/`).

8.  **Python Environment (`python-platform` and `python-tools` roles)**
    -   **Platform:** Installs `pyenv`, reads the target Python version from `.python-version`, installs it, and sets it as the global default.
    -   **Tools:** Installs a list of Python tools from `config/common/python/pipx-tools.txt` using `pipx install`.

9.  **Java Environment (`java` role)**
    -   Installs the `temurin@21` JDK using `homebrew_cask`.

10.  **Node.js Environment (`nodejs-platform` and `nodejs-tools` roles)**
    -   **Platform:** Installs `nvm`, `jq`, and `pnpm`, reads the target Node.js version from `.nvmrc`, installs it, and sets it as the default.
    -   **Tools:** Reads the `global-packages.json` file, parses the list of dependencies, and installs them globally using `pnpm install -g`. It also symlinks the `md-to-pdf-config.js` file to the home directory.