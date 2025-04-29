# MacOS Environment Setup

This tool automates the setup of your development environment by batch installing necessary tools. It's primarily used for setting up after a clean install, unifying environments across multiple Macs, and checking the state of the base environment.

## Directory Structure

```
environment/
├── .github/
│   ├── scripts/
│   └── workflows/
├── git/
├── cli-tools/
├── cursor/
├── macos/
├── node/
├── brew/
├── gems/
├── shell/
├── scripts/
│   ├── setup/
│   └── utils/
├── .gitignore
├── README.md
└── install.sh
```

## Implementation Features

1.  **Rosetta 2 Installation**
    -   For running Intel-based applications on Apple Silicon.

2.  **Homebrew Setup**

3.  **Shell Configuration**
    -   Creates a symbolic link for `.zprofile`.

4.  **Git Configuration**
    -   Creates symbolic links for `git/.gitconfig` and `git/.gitignore_global`.

5.  **macOS Settings**
    -   Applies settings for trackpad, mouse, keyboard, Dock, Finder, screenshots, etc.

6.  **Package Installation from Brewfile**
    -   Installs packages listed in `config/Brewfile` using `brew bundle`.

7.  **Ruby Environment Setup**

8.  **Xcode Installation and Setup**

9.  **Cursor Configuration**
    -   Provides backup and restore functionality for settings.

10. **Flutter Setup**

11. **React Native Setup**

12. **GitHub CLI Configuration**

13. **SSH Key Generation**
    -   Generates an SSH key if one does not exist.
    -   Sets up the SSH agent.

## Setup Instructions

### 1. Clone or Download the Repository

```sh
$ git clone git@github.com:akitorahayashi/environment.git
$ cd environment
```

### 2. Grant Execution Permission

```sh
$ chmod +x install.sh
```

### 3. Update Git Configuration

Before running the installation script, please update your name and email address in `git/.gitconfig`.

### 4. Run the Installation Script

```sh
$ ./install.sh
```

The script is location-independent and automatically detects paths to find necessary files.

### 5. Android Development Environment Setup

For Flutter and React Native app development, launch Android Studio and follow the on-screen instructions to complete the setup.

### 6. React Native Development

After installation, the following operations are possible:

```sh
# Create a new React Native project
$ npx react-native init MyApp

# Navigate to the project directory
$ cd MyApp

# Run on iOS
$ npx react-native run-ios

# Run on Android
$ npx react-native run-android
```

### 7. SSH Key for GitHub

The script generates an SSH key if needed. Add it to your GitHub account.

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

### 8. Configure GitHub CLI

```sh
# Add authentication for GitHub.com
$ gh auth login

# Add authentication for GitHub Enterprise
$ gh auth login --hostname your-enterprise-hostname.com
```

## Custom CLI Tools

This repository provides custom command-line tools to streamline development tasks. These tools are automatically set up (symlinked to `~/bin`) when you run the main `./install.sh` script.

*   **`swstyle`**: Copies standard SwiftLint and SwiftFormat configuration files into your Swift project or Playground.
    *   Details: [`cli-tools/swstyle/SWSTYLE.md`](./cli-tools/swstyle/SWSTYLE.md)

## Cursor Settings Backup and Restore

Scripts are provided to backup and restore your Cursor settings (`settings.json`, `keybindings.json`, etc.).

```bash
# Backup
$ ./cursor/backup_cursor_settings.sh

# Restore
$ ./cursor/restore_cursor_settings.sh
```

## Ruby Development Environment

```bash
# List available Ruby versions
$ rbenv install -l

# Install a version
$ rbenv install 3.2.2

# Set as global default
$ rbenv global 3.2.2
``` 