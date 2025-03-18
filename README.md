# MacOS Environment Setup

This repository contains the `install.sh` script for automatically setting up a macOS environment.
By running this script, you can configure Git settings, install Homebrew, set up Xcode Command Line Tools, install various development tools, and set up SSH keys for GitHub.

## Implementation Features

The `install.sh` script implements the following features:

1. **CI Environment Detection**
   - Automatically detects GitHub Actions environment and applies appropriate settings
   - Supports non-interactive installation mode and error checking

2. **Rosetta 2 Installation (for Apple Silicon)**
   - Automatically installs only on Apple M1/M2 chips
   - Not required for newer Apple Silicon (M3 and later)

3. **Homebrew Setup**
   - Installs if not already installed
   - Uses `/opt/homebrew` for Apple Silicon (ARM) devices
   - Immediate PATH activation

4. **Shell Configuration**
   - Creates symlink for `.zprofile`
   - Applies shell environment settings

5. **Git Configuration**
   - Creates symlinks for `git/.gitconfig` and `git/.gitignore_global`
   - Applies Git settings

6. **macOS Settings**
   - Applies system settings from `macos/setup_mac_settings.sh`
   - Trackpad and mouse speed settings
   - Keyboard repeat rate settings
   - Dock settings (size, auto-hide, hot corners)
   - Finder settings
   - Screenshot save location settings

7. **Package Installation from Brewfile**
   - Installs packages listed in `config/Brewfile` using `brew bundle`
   - **CLI Tools**: `git`, `gh`, `cocoapods`, `fastlane`, `act`, `swiftlint`, `fdupes`, `xcodes`
   - **Development Tools**: `flutter`, `android-studio`, `cursor`
   - **Ruby Environment**: `rbenv`, `ruby-build`
   - **Apps**: `google-chrome`, `slack`, `spotify`, `zoom`, `notion`, `figma`

8. **Ruby Environment Setup (rbenv)**
   - Installs rbenv for Ruby version management
   - Sets up latest stable Ruby version
   - Installs bundler gem for dependency management
   - Configures shell integration for rbenv
   - Enables management of multiple Ruby versions for different projects

9. **Xcode Installation and Setup**
   - Automatically installs Xcode using the `xcodes` CLI tool
   - Configures simulators
   - Verifies installation completion through synchronous execution

10. **SwiftLint Installation**
    - Automatically installs after Xcode installation
    - Verifies functionality

11. **Flutter Configuration**
    - Properly configures Flutter and automatically accepts Android SDK licenses
    - Automatically sets up Android SDK environment
    
12. **GitHub CLI Configuration**
    - Configures GitHub CLI (`gh`) for terminal-based GitHub operations
    - Supports authentication for both GitHub.com and GitHub Enterprise
    - Enables efficient workflow with repositories, issues, and pull requests
    - Facilitates CI/CD operations and release management from terminal
    - After installation, additional authentication can be added via:
      ```bash
      # Add GitHub.com authentication
      gh auth login
      
      # Add GitHub Enterprise authentication
      gh auth login --hostname your-enterprise-hostname.com
      ```
    
13. **SSH Key Generation and Configuration**
    - Generates an SSH key (`id_ed25519`) if it doesn't exist
    - Automatically sets up the SSH agent
    - Configures agent to avoid entering passphrases

14. **Cursor Configuration**
    - Provides backup and restore functionality for settings
    - Configures Flutter SDK integration

15. **Launching Installed Apps**
    - Automatically launches key applications after installation

16. **Error Tracking**
    - Tracks installation success/failure
    - Provides detailed logging

## Directory Structure

```
environment/
├── .github/        # GitHub related settings
│   └── workflows/  # GitHub Actions workflows
├── config/         # Various configuration files
│   ├── Brewfile    # List of Homebrew packages
│   └── gemlist     # Ruby gems to install (currently only bundler)
├── cursor/         # Cursor IDE related settings
├── git/            # Git related settings
│   ├── .gitconfig
│   └── .gitignore_global
├── macos/          # macOS specific settings
├── shell/          # Shell related settings
│   └── .zprofile
└── install.sh      # Main installation script
```

## Setup Instructions

### 1. Clone or Download the Repository

If you have `git` installed, clone the repository:
```sh
git clone git@github.com:akitorahayashi/environment.git ~/environment
cd ~/environment
```

If you don't have `git`, download the repository as a ZIP file and extract it:

1. Access the GitHub repository
2. Click "Download ZIP"
3. Extract the downloaded ZIP file to `~/`
4. Rename the extracted folder to `environment`:
```sh
mv ~/environment-main ~/environment
```

### 2. Grant Execution Permission
```sh
chmod +x install.sh
```

### 3. Update Git Configuration
Before running the installation script, update the Git configuration with your name and email address.

Open `git/.gitconfig` with a text editor and change the following lines to your information:
```
[user]
	name = Your Name
	email = your.email@example.com
```

### 4. Run the Installation Script
```sh
./install.sh
```

This script will:
- Install Homebrew and essential packages
- Apply Git and macOS system settings
- Restore Cursor settings
- Configure Xcode and Flutter

### 5. Create and Register an SSH Key for GitHub
If no SSH key exists, the script will **automatically generate one**.
After setup, you need to manually add the public key to GitHub:
```sh
cat ~/.ssh/id_ed25519.pub
```
Copy the output and add it to your GitHub SSH Key settings.
Then, verify the SSH connection:
```sh
ssh -T git@github.com
```
If you see a message like this, SSH authentication was successful:
```sh
Hi akitorahayashi! You've successfully authenticated, but GitHub does not provide shell access.
```

### 6. Configure GitHub CLI
The script will install GitHub CLI and prompt you for authentication. You can choose between:

- **GitHub.com**: For personal repositories and open-source contributions
- **GitHub Enterprise**: For company repositories (if your organization uses GitHub Enterprise)

**Recommendation**: Start with GitHub.com authentication first, as it's the primary service. You can add GitHub Enterprise authentication later if needed.

You can add multiple authentications after initial setup:
```sh
# Add additional GitHub.com authentication
gh auth login

# Add GitHub Enterprise authentication
gh auth login --hostname your-enterprise-hostname.com
```

Using GitHub CLI will simplify many GitHub operations:
```sh
# Create a pull request
gh pr create

# View and checkout pull requests
gh pr list
gh pr checkout 123

# Check repository status
gh repo view

# Create an issue
gh issue create
```

## Cursor Settings Backup and Restore

### Backup
```bash
./cursor/backup_cursor_settings.sh
```

### Restore
```bash
./cursor/restore_cursor_settings.sh
```

## CI Environment Operation

This script has CI testing implemented with GitHub Actions to verify:
- Whether basic installation and settings function correctly
- Whether there are no issues when run multiple times (idempotence)
- Whether various components are configured correctly

For details, see `.github/workflows/README.md`.

## Ruby Development Environment

The setup includes rbenv for Ruby version management, which enables using multiple Ruby versions on your system.

### Key Components

1. **rbenv**: Ruby version manager
   - Installed via Homebrew
   - Integrated with shell via `.zprofile`
   - Allows switching Ruby versions per project

2. **bundler**: Ruby dependency manager
   - Automatically installed for the default Ruby version
   - Manages project-specific gem dependencies

### Usage

After installation, you can manage Ruby versions and dependencies as follows:

#### Installing Ruby Versions
```bash
# List available Ruby versions
rbenv install -l

# Install a specific Ruby version
rbenv install 3.2.0

# Set global Ruby version
rbenv global 3.2.0

# Set Ruby version for current directory
rbenv local 3.1.2
```

#### Managing Gems
```bash
# Create a new Gemfile for your project
echo 'source "https://rubygems.org"' > Gemfile
echo 'gem "rails"' >> Gemfile

# Install gems specified in Gemfile
bundle install

# Update gems
bundle update
```

#### Working with Multiple Ruby Projects
Each project can have its own Ruby version and gem dependencies:

1. Navigate to your project directory
2. Set the Ruby version: `rbenv local 3.1.2`
3. Create a Gemfile with your project dependencies
4. Run `bundle install` to install the gems

This way, each project maintains its own isolated environment.
