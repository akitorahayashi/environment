# MacOS Environment Setup Script

This repository provides `install.sh`, a script to automate macOS environment setup.  
By running this script, you can apply Git configurations, install Homebrew, set up Xcode Command Line Tools, install various development tools, and configure SSH keys for GitHub.

## Directory Structure

```
environment/
├── config/        # Configuration files
│   └── Brewfile   # Homebrew package list
├── cursor/        # Cursor IDE related settings
├── git/           # Git related settings
│   ├── .gitconfig
│   └── .gitignore_global
├── macos/         # macOS specific settings
├── shell/         # Shell related settings
│   ├── .zprofile
│   └── .zshrc
├── xcode/         # Xcode related settings
└── install.sh     # Main installation script
```

# Setup Instructions

## 1. Clone or Download the Repository

If `git` is available, clone the repository:
```sh
git clone git@github.com:akitorahayashi/environment.git ~/environment
cd ~/environment
```
If git is not available, download the repository as a ZIP file and extract it to the home directory:

1. Go to GitHub repository
2. Click Download ZIP
3. Extract the ZIP file in ~/
4. Rename the extracted folder from environment-main to environment:
```sh
mv ~/environment-main ~/environment
```
The script expects the directory to be named environment, so renaming is required.
## 2. Grant Execution Permission
```sh
chmod +x install.sh
```
## 3. Update Git Configuration
Before running the setup script, you need to update the Git configuration with your own name and email.

Open `git/.gitconfig` using a text editor.

Modify the lines with your own information.
## 4. Run the Setup Script
```sh
./install.sh
```
This script will:
- Install Homebrew & essential packages
- Apply Git & macOS system settings
- Restore Cursor settings
- Configure Xcode & Flutter
## 5. Create and Register an SSH Key for GitHub
If no SSH key exists, the script will **automatically generate one**.
After the setup, you need to manually add the public key to GitHub.
```sh
cat ~/.ssh/id_ed25519.pub
```
Copy the output and add it to your GitHub SSH Key Settings.
Then, verify the SSH connection:
```sh
ssh -T git@github.com
```
If you see a message like this, SSH authentication was successful:
```sh
Hi akitorahayashi! You've successfully authenticated, but GitHub does not provide shell access.
```
## 6. Reload the Shell
After setup is complete, reload the shell to apply the changes.
```sh
exec $SHELL -l
```

# Workflow
## On Your Old Mac
Back up Xcode & Cursor settings
```bash
./xcode/backup_xcode_settings.sh
./cursor/backup_cursor_settings.sh
```
Commit & push to GitHub
## On Your New Mac
Clone your dotfiles & run the setup script
```bash
./install.sh
```
Your Mac is now set up exactly like before! 🎉
# Features
## 1. Git Configuration
`environment/git/.gitconfig` and `environment/git/.gitignore_global` are symlinked to the home directory.

## 2. Homebrew Installation
Installs Homebrew if it is not already installed.
Uses `/opt/homebrew` for Apple Silicon (ARM) devices.

## 3. Install Packages from Brewfile
Installs packages listed in `config/Brewfile` using `brew bundle`.
Main packages included:
- **CLI Tools**: `git`, `gh`, `cocoapods`, `zsh`, `fdupes`
- **Development Tools**: `android-studio`, `flutter`, `cursor`
- **Other Apps**: `google-chrome`, `slack`, `spotify`, `zoom`, `notion`, `figma`

## 4. Xcode Installation and Setup
Automatically installs Xcode using `xcodes` CLI tool.

Before installing `xcodes`, the script adds the necessary Homebrew tap:
```sh
brew tap xcodesorg/homebrew-xcodes
```
Also installs Xcode Command Line Tools if missing.

## 5. Rosetta 2 Installation for Apple Silicon
Installs Rosetta 2 **only on Apple M1/M2 Macs**.  
Newer Apple Silicon chips (M3 and later) do **not** require Rosetta 2.

## 6. Flutter Setup
If Flutter is installed via Homebrew, it will execute
`flutter doctor --android-licenses` to ensure a proper setup.

## 7. SSH Key Generation and Configuration
Generates a new SSH key (`id_ed25519`) if none exists.
Adding the public key to GitHub allows passwordless `git push` operations.

### SSH Agent Auto-Configuration
The script automatically sets up the SSH agent to cache your SSH key:
- Starts the SSH agent if it's not running
- Adds your SSH key to the agent
- Configures `.zshrc` to automatically start the agent and add keys on shell startup
- Eliminates the need to enter your SSH key passphrase repeatedly during the same session

## 8. macOS System Settings Application  
Applies system settings from `macos/setup_mac_settings.sh`, configuring:  
- Trackpad & mouse speed  
- Keyboard repeat rate  
- Dock preferences (size, auto-hide, hot corners)  
- Finder settings (path bar, status bar, hidden files visibility)  
- Screenshot save location

## 9. Cursor Settings Backup & Restore
### Backup Cursor Settings
```bash
./cursor/backup_cursor_settings.sh
```
This saves Cursor IDE settings and configurations.

### Restore Cursor Settings
```bash
./cursor/restore_cursor_settings.sh
```
This will restore your Cursor IDE settings.

## 10. Xcode Settings Backup & Restore
### Backup Xcode Settings
```bash
./xcode/backup_xcode_settings.sh
```
Saves configurations to `environment/xcode/.`

### Restore Xcode Settings
```bash
./xcode/restore_xcode_settings.sh
```
Restores them to `~/Library/Developer/Xcode/UserData/.`