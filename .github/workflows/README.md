# CI for macOS Environment Setup

This document describes the CI (Continuous Integration) setup for the macOS environment setup script (`install.sh`). This CI workflow is designed to automatically verify that the environment setup script works correctly in a clean macOS environment.

## CI Workflow Overview

CI is executed using GitHub Actions at the following times:
- When pushing to the `main` branch
- When creating a pull request targeting the `main` branch
- Manual execution (workflow_dispatch)

## Verification Items

The CI workflow verifies the following items:

### 1. Basic Installation
- Whether Homebrew is correctly installed
- Whether Xcode Command Line Tools are available

### 2. Git Configuration
- Whether the `.gitconfig` file is correctly symlinked
- Whether the `.gitignore_global` file is correctly symlinked
- Whether `core.excludesfile` is correctly configured

### 3. Shell Configuration
- Whether the `.zprofile` file is correctly symlinked

### 4. Homebrew Packages
- Whether important packages (git, xcodes, cursor) are correctly installed

### 5. Flutter Configuration (if installed)
- Whether Android SDK environment variables are correctly set

### 6. Cursor Configuration
- Whether the Cursor application is correctly installed

### 7. Idempotence Test
- Verify that no new installations occur when running the script a second time
- Verify that the script can be safely executed multiple times

## GitHub Actions Usage Limitations

Since this repository is a public repository, the use of GitHub Actions is basically free. However, the following points should be noted:

- macOS runners consume 10x the minutes (100 minutes used counts as 1,000 minutes)
- GitHub Free account's monthly free quota is 2,000 minutes
- Even for public repositories, care should be taken with the number of macOS runner uses

For more details, see [GitHub Actions Pricing](https://docs.github.com/en/billing/managing-billing-for-github-actions/about-billing-for-github-actions).