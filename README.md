# macOS Environment Setup Script

This repository contains the `install.sh` script for automatically setting up a macOS environment.
By running this script, you can configure Git settings, install Homebrew, set up Xcode Command Line Tools, install various development tools, and set up SSH keys for GitHub.

## Directory Structure

```
environment/
├── .github/        # GitHub related settings
│   └── workflows/  # GitHub Actions workflows
├── config/         # Various configuration files
│   └── Brewfile    # List of Homebrew packages
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

## Features

### 1. Git Configuration
Symlinks `environment/git/.gitconfig` and `environment/git/.gitignore_global` to your home directory.

### 2. Homebrew
Installs Homebrew if it's not already installed.
Uses `/opt/homebrew` for Apple Silicon (ARM) devices.

### 3. Package Installation from Brewfile
Installs packages listed in `config/Brewfile` using `brew bundle`:
- **CLI Tools**: `git`, `gh`, `cocoapods`, `fastlane`, `act`, `swiftlint`, `fdupes`, `xcodes`
- **Development Tools**: `flutter`, `android-studio`, `cursor`
- **Apps**: `google-chrome`, `slack`, `spotify`, `zoom`, `notion`, `figma`

### 4. Xcode Installation and Setup
Automatically installs Xcode using the `xcodes` CLI tool.

### 5. Rosetta 2 for Apple Silicon
Automatically installs Rosetta 2 only on Apple M1/M2 Macs.
Not required for newer Apple Silicon (M3 and later).

### 6. Flutter Configuration
If Flutter is installed, it will be properly configured and
Android SDK licenses will be accepted.

### 7. SSH Key Generation and Configuration
Generates an SSH key (`id_ed25519`) if it doesn't exist.
Sets up the SSH agent automatically to save you from entering passphrases:
- Automatically starts the SSH agent
- Adds your SSH key to the agent
- Starts the agent when the shell starts

### 8. macOS System Settings
Applies system settings from `macos/setup_mac_settings.sh`:
- Trackpad and mouse speed
- Keyboard repeat rate
- Dock settings (size, auto-hide, hot corners)
- Finder settings
- Screenshot save location

### 9. Cursor Settings Backup and Restore
#### Backup
```bash
./cursor/backup_cursor_settings.sh
```

#### Restore
```bash
./cursor/restore_cursor_settings.sh
```

## CI Environment Operation

This script has CI testing implemented with GitHub Actions to verify:
- Whether basic installation and settings function correctly
- Whether there are no issues when run multiple times (idempotence)
- Whether various components are configured correctly

For details, see `.github/workflows/README.md`.
