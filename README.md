# MacOS Environment Setup

This tool automates the setup of your development environment by batch installing necessary tools. It's primarily used for setting up after a clean install, unifying environments across multiple Macs, and checking the state of the base environment.

## Dependencies

- **Homebrew**: For package management.
- **Git**: For cloning the repository and managing configurations.
- **stow**: For managing configuration files (symlinks). This is installed automatically via the Brewfile.

## Directory Structure

```
environment/
├── .github/
│   └── workflows/
├── config/
│   ├── brew/
│   ├── cursor/
│   ├── gems/
│   ├── git/
│   ├── node/
│   └── shell/
├── macos/
├── scripts/
│   ├── setup/
│   └── utils/
├── .gitignore
├── install.sh
└── README.md
```

## Implementation Features

1.  **Rosetta 2 Installation**
    -   For running Intel-based applications on Apple Silicon.

2.  **Homebrew Setup**
    -   Installs Homebrew and required command-line tools.

3.  **Shell Configuration**
    -   Uses `stow` to create a symbolic link for `.zprofile` from `config/shell/` to `$HOME`.

4.  **Git Configuration**
    -   Uses `stow` to create symbolic links for `.gitconfig` and `.gitignore_global` from `config/git/` to `$HOME`.

5.  **macOS Settings**
    -   Applies settings for trackpad, mouse, keyboard, Dock, Finder, screenshots, etc.

6.  **Package Installation from Brewfile**
    -   Installs packages listed in `config/brew/Brewfile` using `brew bundle`.

7.  **Ruby Environment Setup**

8.  **Xcode Installation and Setup**

9.  **Cursor Configuration**
    -   Uses `stow` to create symbolic links for settings (`settings.json`, `keybindings.json`, etc.) from `config/cursor/` to `$HOME/Library/Application Support/Cursor/User`.

10. **Flutter Setup**

11. **React Native Setup** (Placeholder - check actual implementation)

12. **GitHub CLI Configuration**

13. **SSH Key Generation**
    -   Generates an SSH key (`id_ed25519`) if one does not exist.
    -   Sets up the SSH agent.

14. **Neovim Configuration**
    -   Uses `stow` to create symbolic links for Neovim configuration from `config/nvim/` to `$HOME/.config/nvim`.

## Setup Instructions

### 1. Clone or Download the Repository

```sh
$ git clone git@github.com:akitorahayashi/environment.git
$ cd environment
```

### 2. Grant Execution Permission

```sh
$ chmod +x install.sh
$ chmod +x scripts/setup/*.sh
```

### 3. Update Git Configuration (Optional but Recommended)

Before running the installation script, you might want to update your name and email address in `config/git/.gitconfig`.

### 4. Run the Installation Script

```sh
$ ./install.sh
```

The script is location-independent and automatically detects paths to find necessary files. It will install Homebrew, `stow`, and other dependencies if they are missing.

### 5. Individual Setup Scripts

Each setup script in `scripts/setup/` can be run independently. These scripts are idempotent, meaning they can be run multiple times safely. Here's how to use them:

```sh
# Homebrew setup
$ ./scripts/setup/homebrew.sh

# Shell configuration
$ ./scripts/setup/shell.sh

# Git configuration
$ ./scripts/setup/git.sh

# Ruby environment setup
$ ./scripts/setup/ruby.sh

# Xcode setup
$ ./scripts/setup/xcode.sh

# Flutter setup
$ ./scripts/setup/flutter.sh

# Cursor configuration
$ ./scripts/setup/cursor.sh

# macOS settings
$ ./scripts/setup/mac.sh
```

Each script includes:
- Dependency checks
- Installation/configuration steps
- Verification of the setup
- Detailed logging
- Error handling

The scripts will:
1. Check if components are already installed/configured
2. Install or configure only if necessary
3. Verify the setup
4. Provide detailed feedback about the process

### 6. Apply Shell Configuration

After the script finishes, restart your terminal or run `source ~/.zprofile` to apply the shell settings.

### 7. Android Development Environment Setup

For Flutter app development, launch Android Studio and follow the on-screen instructions to complete the setup.

### 8. SSH Key for GitHub

The script generates an SSH key if needed. Add the public key (`~/.ssh/id_ed25519.pub`) to your GitHub account.

```sh
$ cat ~/.ssh/id_ed25519.pub
```

Verify the connection:

```sh
$ ssh -T git@github.com
```

On success, a message similar to the following will be displayed:

```
Hi ${GITHUB_USERNAME}! You've successfully authenticated, but GitHub does not provide shell access.
```

### 9. Configure GitHub CLI

If prompted during the script or if skipped, authenticate the GitHub CLI:

```sh
# Add authentication for GitHub.com
$ gh auth login

# Add authentication for GitHub Enterprise (if applicable)
$ gh auth login --hostname your-enterprise-hostname.com
```

## Managing Configuration Files (Dotfiles)

This setup uses `stow` to manage configuration files located in the `config/` directory. `stow` creates symbolic links from the files in this repository to their expected locations in your home directory (e.g., `config/git/.gitconfig` is linked to `$HOME/.gitconfig`).

- To add new configuration files for an existing tool (e.g., git), place them in the corresponding directory (e.g., `config/git/`) and re-run `./install.sh`.
- To add configuration for a new tool, create a new directory under `config/` (e.g., `config/mytool/`), place the configuration files inside, add a setup step in `install.sh` (likely involving `stow`), and add a corresponding setup script in `scripts/setup/`.
- Changes made directly to the linked files (e.g., changing settings via the Cursor UI) will modify the files within this repository directly. Commit these changes to Git to save them.

## Ruby Development Environment

```bash
# List available Ruby versions
$ rbenv install -l

# Install a version
$ rbenv install 3.2.2

# Set as global default
$ rbenv global 3.2.2
``` 