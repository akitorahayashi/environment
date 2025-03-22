# CI Workflow

This directory contains the Continuous Integration (CI) workflow configuration for automating the validation of the macOS environment setup process.

## Overview

The CI workflow (`ci.yml`) is designed to:

1. Validate that the installation script (`install.sh`) works correctly on macOS
2. Ensure all tools and applications are properly installed and configured
3. Verify the idempotency of the installation script (can be run multiple times without side effects)
4. Confirm all configuration files are properly set up

## Idempotency Testing

Idempotency is a critical property of our installation scripts, ensuring they can be run multiple times without causing unintended side effects or errors. Our CI workflow tests this by:

1. **First Run Validation**: Installing all components from scratch and verifying successful installation
2. **Repeated Execution**: Running the installation script a second time to ensure:
   - No errors or failures occur
   - No unnecessary reinstallations take place
   - Existing configurations are not corrupted
   - The system remains in a consistent state

This ensures that developers can safely run the installation script multiple times for updates or repairs without worrying about breaking their environment. Each component's setup script includes checks to detect if installation is already complete, and skips redundant operations when appropriate.

### Benefits of Idempotent Scripts

- **Safety**: Prevents accidental corruption of working environments
- **Consistency**: Ensures the same end state regardless of initial conditions
- **Maintainability**: Allows incremental updates without full reinstallation
- **Self-Healing**: Enables repairing partial installations or updates

## Workflow Details

### Triggers

The workflow runs on:
- Push to the `main` branch
- Pull requests to the `main` branch
- Manual execution via workflow dispatch

### Environment

- **Runner**: Latest macOS version
- **Timeout**: 120 minutes (extended to accommodate Xcode installation)

### Jobs

The workflow consists of two main jobs:

#### 1. `test-install`

This job performs the actual installation and verification:

- **Repository Checkout**: Clones the repository
- **GitHub Authentication Setup**: Configures authentication for the CI environment
- **Script Permissions**: Ensures all scripts have execution permissions
- **Installation Script Execution**: Runs `install.sh` with CI environment variables
- **Environment Verification**: Runs `ci_verify.sh` to validate the installed environment

#### 2. `summary`

This job provides a summary of the overall CI process after the test-install job completes.

### Environment Variables Used

- `JAVA_HOME`: Java installation directory
- `ANDROID_SDK_ROOT`: Android SDK location
- `REPO_ROOT`: Repository root directory
- `IS_CI`: Flag indicating CI environment
- `ALLOW_COMPONENT_FAILURE`: Allows continuing even if non-critical components fail
- `ANDROID_LICENSES`: Automatically accepts Android licenses
- `GITHUB_TOKEN_CI`: Token for GitHub authentication

## Verification Process

The `ci_verify.sh` script performs comprehensive validation of all installed components:

### Homebrew Validation
- Verifies `brew` command availability
- Checks Homebrew version information

### Brewfile Package Validation
- Counts total packages listed in Brewfile
- Verifies installation of all formulas and casks
- Reports any missing packages

### Xcode Validation
- Verifies Xcode Command Line Tools installation
- Confirms Xcode 16.2 installation
- Checks iOS, watchOS, tvOS, and visionOS simulators

### Android SDK Validation
- Verifies Android SDK installation and configuration

### Flutter Validation
- Confirms Flutter installation and setup
- Verifies Flutter environment configuration

### Git Configuration Validation
- Checks Git setup and configuration

### Ruby Environment Validation
- Verifies Ruby installation and setup

### Cursor IDE Validation
- Confirms Cursor installation and configuration

### Shell Configuration Validation
- Verifies shell environment setup

### macOS Settings Validation
- Checks macOS system configuration

## Verification Results

The verification process provides:
- Individual results for each component
- A summary of total verifications performed
- Count of successful and failed verifications
- Overall status of the environment setup

## Using the CI Workflow

This workflow serves as both validation of the installation process and documentation of expected environment state after installation. Developers can refer to the verification scripts to understand what components should be properly installed and configured.
