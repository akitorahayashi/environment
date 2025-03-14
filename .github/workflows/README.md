# CI Workflow 

This directory contains the Continuous Integration (CI) workflow configuration for automating the validation of the macOS environment setup process.

## Overview

The CI workflow (`ci.yml`) is designed to:

1. Validate the installation script (`install.sh`) works correctly on macOS
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

- **Runner**: macOS latest
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
   - **Homebrew**: Verifies Homebrew is installed correctly
   - **Xcode**: Confirms Xcode Command Line Tools, Xcode 16.2, and simulators
   - **Git**: Ensures Git configuration files are properly linked
   - **Shell**: Checks shell configuration is correctly applied
   - **Homebrew Packages**: Validates all packages in Brewfile are installed
   - **Flutter**: Confirms Flutter is properly installed and configured
   - **Cursor**: Checks Cursor IDE configuration (settings, extensions, Flutter SDK path)
   - **macOS Settings**: Analyzes the macOS system settings configuration

5. **Idempotency Test**
   - Runs the installation script a second time
   - Ensures no new installations are performed
   - Checks for specific keywords that would indicate non-idempotent behavior

## Key Validation Checks

### Flutter SDK Configuration
- Verifies Flutter is installed at `/opt/homebrew/bin/flutter`
- Runs `flutter doctor` to validate the installation
- Confirms Xcode integration

### Cursor IDE Setup
- Validates Cursor is installed via Homebrew
- Checks for required configuration files (settings.json, extensions.json)
- Confirms Flutter SDK path integration
- Counts defined extensions

### macOS System Settings
- Analyzes settings file for common configurations (Dock, Finder, screenshots)
- Performs syntax validation
- Checks for potentially dangerous commands

## Modifying the Workflow

When modifying the CI workflow:
1. Update the steps to match any changes in the installation script
2. Ensure timeout values are appropriate for all installation steps
3. Add validation for any new tools or configurations
4. Update the idempotency test patterns as needed
