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
│       ├── brew/
│       ├── nodejs/
│       └── python/
│   └── macbook-only/
│       ├── brew/
│       ├── nodejs/
│       └── python/
├── ansible/
│   ├── hosts
│   ├── playbook.yml
│   ├── roles/
│   │   ├── brew/
│   │   ├── git/
│   │   ├── java/
│   │   ├── nodejs/
│   │   ├── python/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── system_defaults/
│   │   ├── vscode/
│   │   └── flutter/
│   └── utils/
│       └── backup-system-defaults.sh
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

This project has been refactored to use Ansible for improved idempotency and maintainability. All setup logic has been migrated from shell scripts to Ansible roles.

1.  **Homebrew Setup**
    -   Installs Homebrew and necessary command-line tools using Ansible's `community.general.homebrew` module.

2.  **Shell Configuration**
    -   Running `just cmn-shell` creates symbolic links for common shell settings (`.zprofile` and `.zshrc`) in the home directory using Ansible's `file` module.
    -   These settings are located in `config/common/shell/`.

3.  **Git Configuration**
    -   Executes Ansible role `git` to perform basic Git setup.
    -   This includes copying `.gitconfig`, setting up a global `.gitignore`, and configuring user information (name, email address) from environment variables using Ansible's `git_config` module.

4.  **GitHub CLI (gh) Configuration**
    -   Executes Ansible role `git` to configure the GitHub CLI (`gh`).
    -   This includes installing `gh` and creating symbolic links for configuration files.

5.  **macOS Settings**
    -   Running `just cmn-apply-defaults` applies system settings using Ansible's `community.general.osx_defaults` module.
    -   Running `just cmn-backup-defaults` generates/updates the current macOS system defaults (calls the backup script in `ansible/utils/`).

6.  **Package Installation from Brewfile**
    -   Installs packages listed in `config/common/brew/Brewfile` using Ansible's `community.general.homebrew` module with `brewfile` parameter.

7.  **Ruby Environment Setup**
    -   Installs `rbenv` and `ruby-build` using Ansible's `homebrew` module.
    -   Installs a specific version of Ruby and sets it globally using shell commands with `creates` for idempotency.
    -   Installs gems using `bundler`.

8.  **VS Code Configuration**
    -   Creates symbolic links for configuration files from `config/common/vscode/` to `$HOME/Library/Application Support/Code/User` using Ansible's `file` module.

9.  **Python Environment Setup**
    -   Installs `pyenv` and `uv` using Ansible's `homebrew` module.
    -   Installs a specific version of Python and sets it globally.
    -   Installs pipx tools from configuration files using Ansible's `pipx` module.

10. **Java Environment Setup**
    -   Installs a specific version of Java (Temurin) using Ansible's `community.general.homebrew_cask` module.

11. **Node.js Environment Setup**
    -   Installs `nvm`, `jq`, and `pnpm` with Ansible's `homebrew` module.
    -   Installs a specific version of Node.js and sets it as the default using shell commands.
    -   Installs global npm packages based on `config/common/nodejs/global-packages.json` using Ansible's shell module.