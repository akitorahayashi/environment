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
│   │   └── brew/
│   └── macbook-only/
│       ├── brew/
│       ├── node/
│       └── python/
├── scripts/
│   ├── nodejs/
│   │   ├── platform.sh
│   │   └── tools.sh
│   ├── python/
│   │   ├── platform.sh
│   │   └── tools.sh
│   ├── system-defaults/
│   │   ├── apply-system-defaults.sh
│   │   └── backup-system-defaults.sh
│   ├── flutter.sh
│   ├── git.sh
│   ├── gh.sh
│   ├── brew.sh
│   ├── java.sh
│   ├── shell.sh
│   ├── ruby.sh
│   └── vscode.sh
├── .gitignore
├── Makefile
├── justfile
└── README.md
```

## Implemented Features

1.  **Homebrew Setup**
    -   Installs Homebrew and necessary command-line tools.

2.  **Shell Configuration**
    -   Running `make shell` creates symbolic links for common shell settings (`.zprofile` and `.zshrc`) in the home directory.
    -   These settings are located in `config/common/shell/`.

3.  **Git Configuration**
    -   Executes `scripts/git.sh` to perform basic Git setup.
    -   This includes copying `.gitconfig`, setting up a global `.gitignore`, and configuring user information (name, email address) from the `.env` file.

4.  **GitHub CLI (gh) Configuration**
    -   Executes `scripts/gh.sh` to configure the GitHub CLI (`gh`).
    -   This includes installing `gh` and setting up command aliases. Aliases are managed with the `gh alias set` command, not as shell aliases in `.zshrc`.

5.  **macOS Settings**
    -   Running `make apply-defaults` applies system settings (system defaults) based on `scripts/system-defaults/apply-system-defaults.sh`.
    -   Running `make backup-defaults` generates/updates the current macOS system defaults (internally calls `scripts/system-defaults/backup-system-defaults.sh`).

6.  **Package Installation from Brewfile**
    -   Installs packages listed in `config/common/brew/Brewfile` using `brew bundle`.

7.  **Ruby Environment Setup**
    -   Installs `rbenv` and `ruby-build`.
    -   Installs a specific version of Ruby and sets it globally.
    -   Installs gems using `bundler` based on `config/common/ruby/global-gems.rb`.

8.  **VS Code Configuration**
    -   Creates symbolic links for configuration files from `config/common/vscode/` to `$HOME/Library/Application Support/Code/User`.

9.  **Python Environment Setup**
    -   Installs `pyenv`.
    -   Installs a specific version of Python and sets it globally.

10. **Java Environment Setup**
    -   Installs a specific version of Java (Temurin) using `Homebrew`.

11. **Node.js Environment Setup**
    -   Installs `nvm` and `jq` with Homebrew.
    -   Installs a specific version of Node.js and sets it as the default.
    -   Installs global npm packages based on `config/common/nodejs/global-packages.json`.

12. **Flutter Setup**

## How to Use

This project uses a two-step approach:
1. **Bootstrap Setup**: Use `make` to install Homebrew and the `just` command runner
2. **Full Setup**: Use `make` to delegate to `just` for the actual environment setup

### Bootstrap Commands

- **`make` or `make help`**: Displays all available commands and their descriptions.
- **`make setup`**: Installs Homebrew and the `just` command runner (required first step).

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

    Install Homebrew, the `just` command runner, and create the `.env` file:
    ```sh
    make setup
    ```

    This command will:
    - Create a `.env` file from `.env.example` if it doesn't exist
    - Install Homebrew if not already installed
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
    These commands install all the necessary development tools such as Git, Ruby, Python, Node.js, and also apply macOS and shell settings. The Makefile delegates the actual setup work to `just` recipes.

4.  **Restart macOS**

    Please restart macOS to apply all settings completely.