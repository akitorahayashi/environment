# MacOS Environment Setup

This repository contains the `install.sh` script for automatically setting up a macOS environment.

## Implementation Features

The `install.sh` script implements the following features:

1. **Rosetta 2 Installation (for Apple Silicon)**
   - Automatically installs only on Apple M1/M2 chips
   - Not required for newer Apple Silicon (M3 and later)

2. **Homebrew Setup**
   - Installs if not already installed
   - Uses `/opt/homebrew` for Apple Silicon (ARM) devices
   - Immediate PATH activation

3. **Shell Configuration**
   - Creates symlink for `.zprofile`
   - Applies shell environment settings

4. **Git Configuration**
   - Creates symlinks for `git/.gitconfig` and `git/.gitignore_global`
   - Applies Git settings

5. **macOS Settings**
   - Applies system settings from `macos/setup_mac_settings.sh`
   - Trackpad and mouse speed settings
   - Keyboard repeat rate settings
   - Dock settings (size, auto-hide, hot corners)
   - Finder settings
   - Screenshot save location settings

6. **Package Installation from Brewfile**
   - Installs packages listed in `config/Brewfile` using `brew bundle`
   - **CLI Tools**: `git`, `gh`, `cocoapods`, `fastlane`, `act`, `swiftlint`, `fdupes`, `xcodes`
   - **Development Tools**: `flutter`, `android-studio`, `cursor`
   - **Ruby Environment**: `rbenv`, `ruby-build`
   - **Apps**: `google-chrome`, `slack`, `spotify`, `zoom`, `notion`, `figma`

7. **Ruby Environment Setup (rbenv)**
   - Installs rbenv for Ruby version management
   - Sets up latest stable Ruby version
   - Installs bundler gem for dependency management
   - Configures shell integration for rbenv
   - Enables management of multiple Ruby versions for different projects

8. **Xcode Installation and Setup**
   - Automatically installs Xcode using the `xcodes` CLI tool
   - Configures simulators
   - Verifies installation completion through synchronous execution

9. **SwiftLint Installation**
    - Automatically installs after Xcode installation
    - Verifies functionality

10. **Flutter Configuration**
    - Basic Flutter environment configuration
    - Flutter installation and PATH configuration
    - Note: Android development environment is configured during the first launch of Android Studio

11. **GitHub CLI Configuration**
    - Configures GitHub CLI (`gh`) for terminal-based GitHub operations
    - Supports authentication for both GitHub.com and GitHub Enterprise
    - Enables efficient workflow with repositories, issues, and pull requests
    - After installation, additional authentication can be added via:
      ```bash
      # Add GitHub.com authentication
      gh auth login
      
      # Add GitHub Enterprise authentication
      gh auth login --hostname your-enterprise-hostname.com
      ```
    
12. **SSH Key Generation and Configuration**
    - Generates an SSH key (`id_ed25519`) if it doesn't exist
    - Automatically sets up the SSH agent
    - Configures agent to avoid entering passphrases

13. **Cursor Configuration**
    - Provides backup and restore functionality for settings
    - Configures Flutter SDK integration

## Directory Structure

```
environment/
├── .github/        # GitHub関連の設定
│   └── workflows/  # GitHub Actions
│       ├── ci.yml           # CI設定ファイル
│       └── ci_verify.sh     # CI検証のためのスクリプト
├── config/         
│   ├── Brewfile    # Homebrewパッケージリスト
│   └── gemlist     # グローバルにインストールするRuby gems（現在はbundlerのみ）
├── cursor/         # Cursor IDEの設定
├── git/            # Git関連の設定
│   ├── .gitconfig
│   └── .gitignore_global
├── macos/          # macOS固有の設定
├── scripts/        
│   ├── setup/      
│   │   ├── android.sh      # Android SDKのセットアップ
│   │   ├── cursor.sh       # Cursorのセットアップ
│   │   ├── flutter.sh      # Flutterのセットアップ
│   │   ├── git.sh          # Git関連のセットアップ
│   │   ├── homebrew.sh     # Homebrewのセットアップ
│   │   ├── mac.sh          # macOSのセットアップ
│   │   ├── ruby.sh         # Ruby環境のセットアップ
│   │   ├── shell.sh        # シェルのセットアップ
│   │   └── xcode.sh        # Xcodeのセットアップ
│   └── utils/      # ユーティリティ
│       ├── helpers.sh      
│       └── logging.sh      
├── shell/          # シェル関連の設定
│   └── .zprofile
└── install.sh      # インストールを実行するスクリプト
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

### 5. Android Development Environment Setup

For Flutter app development, you need to launch Android Studio for the first time:

```sh
# Launch Android Studio
open -a "Android Studio"
```

During first launch, the following will be automatically configured:
- Android SDK components download
- Installation of necessary platforms and build tools
- Emulator setup
- License agreements

This will resolve any Android-related warnings in Flutter doctor.

### 6. Create and Register an SSH Key for GitHub
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

### 7. Configure GitHub CLI
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
