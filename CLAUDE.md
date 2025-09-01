## CLAUDE.md Self-Modification Obligation

**Important**: This document governs the behavior of the claudecode agent itself. When changes are made to the codebase (adding dependencies, changing file structure, updating coding standards, etc.), claudecode is obligated to update this `CLAUDE.md` and any referenced `CLAUDE.md` files as part of the transaction to maintain consistency.

## Project Overview and Mission

This project, "MacOS Environment Setup," automates the configuration of a complete development environment on macOS. Its mission is to ensure a consistent, reproducible, and version-controlled setup across different machines (specifically MacBook and Mac mini) using a `Makefile` as the primary interface. The system is designed to be idempotent, allowing setup commands to be run multiple times without causing unintended side effects.

## Technology Stack and Environment

- **Orchestration**: `make`. This is the single entry point for all operations.
- **Scripting Language**: `bash`.
- **Package Manager**: Homebrew.
- **Core Runtimes and Version Managers**:
    - **Ruby**: Managed by `rbenv`. Version is defined in `config/common/ruby/.ruby-version`.
    - **Python**: Managed by `pyenv`. Version is defined in `config/common/python/.python-version`.
    - **Node.js**: Managed by `nvm`. Version is defined in `config/common/node/.nvmrc`.
    - **Java**: Must use `temurin@21` installed via Homebrew.
    - **Flutter**: Managed by `fvm`.
- **Key Tools**: Git, GitHub CLI (`gh`), Visual Studio Code, Docker.
- **CI/CD**: GitHub Actions.

## Architectural Principles and File Structure

This repository follows a strict separation of orchestration (`Makefile`), configuration (`config/`), logic (`scripts/`), and testing (`.github/workflows/`).

1.  **`Makefile` (Root)**: The single entry point for all setup operations. It orchestrates the execution of scripts based on user-facing targets like `macbook` or `common`.

2.  **`config/` Directory**: Contains all configuration data, defining *what* to install and configure. It uses a layered model with a `common` base and machine-specific overrides. **For detailed principles on configuration structure and file formats, see `@config/CLAUDE.md`.**

3.  **`scripts/` Directory**: Contains all automation logic, defining *how* to perform the setup. Each script is an idempotent module responsible for a single component. **For the mandatory contract that all scripts must follow, including standards for idempotency and verification, see `@scripts/CLAUDE.md`.**

4.  **`.github/workflows/` Directory**: Defines the CI pipeline using GitHub Actions to automatically test all setup scripts for correctness and idempotency. **For a detailed explanation of the CI architecture and testing procedures, see `@.github/workflows/CLAUDE.md`.**

## Coding Standards and Style Guide

- **General**: All components must adhere to the principle of idempotency. The system must be fully automated and require no interactive input.
- **Makefile**: User-facing targets must be documented (`## ...`). Internal targets must be prefixed with an underscore (`_`).
- **Scripts & CI**: Specific, strict coding standards for scripts and CI workflows are defined in their respective `CLAUDE.md` files. Refer to `@scripts/CLAUDE.md` and `@.github/workflows/CLAUDE.md` for these rules.

## Critical Business Logic and Invariants

- **Idempotency is paramount**: All setup scripts must be runnable multiple times without changing the final state or causing errors after the first successful run. The CI process strictly enforces this.
- **Configuration as the Source of Truth**: Scripts must be stateless and driven by data from the `/config` directory. Never hardcode versions, package names, or settings within the scripts.
- **Layered Configuration**: The `common` configuration is always applied before a machine-specific configuration, allowing for precise overrides.
- **User Secrets**: User-specific credentials (Git username/email) must be provided via a local, git-ignored `.env` file.

## Testing Strategy and Procedures

The entire testing strategy is implemented via the CI pipeline, which serves as the primary mechanism for quality assurance. The core procedure is a strict idempotency check where setup scripts are run twice, and the second run must produce no "violation" side effects. For the definitive guide on testing, **see `@.github/workflows/CLAUDE.md`.**

## CI Process

The CI pipeline is defined in `.github/workflows/` and is triggered on pushes and pull requests to the `main` branch. It uses a modular architecture with reusable workflows to test each component of the environment setup on a `macos-15` runner. Its primary goal is to verify that all scripts execute correctly and are idempotent. For a complete overview of the CI process, **refer to `@.github/workflows/CLAUDE.md`.**

## Does Not Do

- This repository does not manage project-specific dependencies. It only sets up global tools and runtimes.
- It does not manage user data or documents.
- It does not manage security credentials (e.g., API keys, SSH keys) beyond the basic Git user configuration.
- It does not configure deep system settings like network interfaces or firewalls.