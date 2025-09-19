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
│   ├── homebrew.sh
│   ├── java.sh
│   ├── shell.sh
│   ├── ruby.sh
│   └── vscode.sh
├── .gitignore
├── Makefile
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

Use the `make` command to run the setup.

- **`make` or `make help`**: Displays all available commands and their descriptions.

### Full Setup

- **`make macbook`**: Sequentially executes all setup scripts for MacBook.
- **`make mac-mini`**: Sequentially executes all setup scripts for Mac mini.

### Running Individual/Common Tasks

- **`make common`**: Executes all common settings only (Git, VS Code, Ruby, Python, Java, Flutter, Node.js, Shell, System Defaults).
- **`make <task>`**: Executes an individual setup.
  - **Common Tasks**: You can run specific common tasks like `make git`, `make shell`, `make java`, etc.
  - **Machine-Specific Tasks**: Machine-specific tasks like `make mbk-brew`, `make mmn-brew` can also be run individually.

## Setup Instructions

1.  **Install Xcode Command Line Tools**

    ```sh
    xcode-select --install
    ```

2.  **Personal Git Configuration (Create `.env` file)**

    Copy `.env.example` at the root of the repository to create an `.env` file.
    Then, edit `GIT_USERNAME` and `GIT_EMAIL` in the `.env` file to your own.

    ```sh
    cp .env.example .env
    # Edit the .env file to set your GIT_USERNAME and GIT_EMAIL
    ```
    This `.env` file will be automatically loaded by `make macbook` or `make git` in the next step and reflected in the global Git configuration.

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
    This command installs all the necessary development tools such as Homebrew, Git, Ruby, Python, Node.js, and also applies macOS and shell settings.

4.  **Restart macOS**

    Please restart macOS to apply all settings completely.