# CI Workflow 

This directory contains the Continuous Integration (CI) workflow configuration for automating the validation of the macOS environment setup process.

## Overview

The CI workflow (`ci.yml`) is designed to:

1. Validate that the installation script (`install.sh`) works correctly on macOS
2. Ensure all tools and applications are properly installed and configured
3. Verify the idempotency of the installation script (can be run multiple times without side effects)
4. Confirm all configuration files are properly set up

## Workflow Details

### Triggers

The workflow runs on:
- Push to the `main` branch
- Pull requests to the `main` branch
- Manual execution via workflow dispatch

### Environment

- **Runner**: Latest macOS version
- **Timeout**: 120 minutes (extended to accommodate Xcode installation)

### Steps Overview

1. **Repository Checkout**
   - Clones the repository into the CI environment

2. **GitHub Authentication Setup**
   - Configures GitHub authentication for the CI environment

3. **Installation Script Execution**
   - Runs the `install.sh` script with CI-specific environment variables
   - Uses `GITHUB_TOKEN_CI` for authentication with GitHub APIs

4. **Validation Steps**
   - **Homebrew**: Verifies PATH (before and after installation), version check
   - **Xcode**: Confirms Command Line Tools, Xcode 16.2, and various simulators
   - **SwiftLint**: Verifies installation and functionality
   - **Git**: Ensures correct symlinks for configuration files
   - **Shell**: Verifies zprofile settings
   - **Homebrew Packages**: Validates all packages listed in Brewfile are installed
   - **Flutter**: Checks installation, configuration, path, and verification via flutter doctor
   - **Cursor**: Validates IDE settings, extensions, Flutter SDK path
   - **Cursor Extensions**: Verifies extensions are correctly installed from extensions.json
   - **Cask Apps**: Confirms installed applications and launch target settings
   - **macOS Settings**: Analyzes settings files and key categories
   - **Installation Script Improvements**: Validates PATH fixes, Xcode installation wait, SwiftLint installation, error tracking, app launch functionality

5. **Overall Validation Results**
   - Displays summary of all test results

## Key Validation Areas

### Homebrew Validation
- Proper PATH configuration (before and after installation)
- Availability of brew command
- Version information verification

### Xcode Validation
- Command Line Tools installation verification
- Xcode 16.2 installation verification
- iOS, watchOS, tvOS, visionOS simulator verification

### Git Configuration Validation
- Existence of `.gitconfig` and `.gitignore_global`
- Proper symlink configuration
- Git excludesfile settings verification

### Shell Configuration Validation
- Existence and symlink verification for `.zprofile`

### Homebrew Package Validation
- Installation verification for all packages (formula/cask) listed in Brewfile
- Verification of total installed package count

### Flutter Configuration Validation
- Installation path verification (`/opt/homebrew/bin/flutter`)
- Functionality verification via `flutter doctor`
- Xcode integration verification

### Cursor IDE Validation
- Installation verification via Homebrew
- Configuration file verification (settings.json, extensions.json)
- Flutter SDK path settings verification
- Count of defined extensions
- Active verification of extension installation using Cursor CLI
- Dynamic extension list extraction from extensions.json

### macOS Settings Validation
- Existence of settings files
- Key setting categories like Dock, Finder, screenshots
- Analysis of setting item count

## Installation Script Improvement Validation
- Immediate Homebrew PATH activation
- Synchronous Xcode installation execution
- Direct SwiftLint installation process
- Installation state tracking
- App launch functionality improvements
- Enhanced Cursor extension installation and verification
