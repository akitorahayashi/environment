## CLAUDE.md Self-Modification Obligation

**Important**: This document governs the behavior of the claudecode agent itself. When new scripts are added or the fundamental structure of existing scripts is changed, claudecode is obligated to update this `CLAUDE.md` as part of the transaction to reflect the new patterns and standards.

## Module Roles and Responsibilities

The `scripts/` directory contains all the executable logic for the macOS environment setup. Its role is to implement the *how* of the setup process, taking instructions and data from the `/config` directory and being orchestrated by the root `Makefile`. Each script is a self-contained, idempotent module responsible for setting up a specific tool or system component.

## Technology Stack and Environment

- **Primary Language**: All scripts in this directory must be written in `bash`.
- **Execution Environment**: Scripts are executed via `make` on a macOS system. They must be compatible with the default `bash` version available on recent macOS versions.
- **Dependencies**: Scripts may depend on Homebrew for installing tools. Any required dependency must be installed via `brew install` within the script itself if not already present.

## Architectural Principles and File Structure

1.  **Modularity**: Each script must have a single, well-defined responsibility.
    - For simple tools (e.g., Git, Java), a single `[tool].sh` script is sufficient.
    - For complex tools with a multi-stage setup (e.g., Python, Node.js), separate the logic into `platform.sh` (for the version manager and runtime) and `tools.sh` (for global packages/tools).

2.  **Orchestration**: Scripts must never be executed directly by the user. They are designed to be called exclusively from the root `Makefile`. This ensures that required environment variables like `REPO_ROOT` are always set.

3.  **Configuration Separation**: Scripts must be stateless and logic-driven. All configuration data (versions, package names, settings) must be read from files in the `/config` directory. Never hardcode configuration values within a script.

## Coding Standards and Style Guide

Adherence to this contract is mandatory for all scripts within this directory.

1.  **Script Header**:
    - Every script must begin with `#!/bin/bash`.
    - Immediately following, every script must include `set -euo pipefail` to ensure robust error handling.

2.  **Input Contract**:
    - Every script must expect the path to the relevant configuration directory (e.g., `config/common`) as its first positional argument (`$1`).
    - Every script must depend on the `REPO_ROOT` environment variable to construct absolute paths.
    - At the beginning of the script, you must validate the presence of both the config path argument and the `REPO_ROOT` variable, exiting with a clear error message if either is missing.

3.  **Idempotency Contract**:
    - Before performing any action that modifies the system (installing, linking, writing a file), you must first check if the desired state is already achieved.
    - If a modification is necessary, the script must perform the action. Immediately after a successful modification, the script must print the exact string `IDEMPOTENCY_VIOLATION` to standard error (`>&2`). This is a strict requirement for the CI process.

4.  **Logging**:
    - Use a consistent logging format to report progress.
    - `echo "[INFO] ..."` for informational messages.
    - `echo "[SUCCESS] ..."` for successful completion of major steps.
    - `echo "[ERROR] ..."` for fatal errors before exiting.
    - `echo "[INSTALL] ..."` when installing a new package or tool.

5.  **Verification Block**:
    - Every script must end with a dedicated verification section, clearly marked with `==== Start: Verifying... ====`.
    - This block must independently verify that the component was configured correctly (e.g., checking command existence, version numbers, symlink targets).
    - If verification fails, print an `[ERROR]` message and `exit 1`.
    - If all verifications pass, print a final `[SUCCESS]` message for the verification phase.

## Critical Business Logic and Invariants

- **Atomicity**: Each script should be treated as a transaction. If any part of the script fails, the entire `make` process will halt due to `set -e`. The script should not leave the system in a broken or partially configured state.
- **Independence**: A script for one tool (e.g., `ruby.sh`) must not depend on the successful execution of another tool's script (e.g., `python.sh`), except for foundational dependencies like Homebrew.
- **Verification is Truth**: The final verification block is the source of truth for a script's success. Even if all setup commands run without error, the script is only considered successful if the verification block passes.

## Testing Strategy and Procedures

- The primary testing method is execution within the CI pipeline.
- **Idempotency Test**: The core test for every script is the idempotency check. The CI runner executes the script twice. The test fails if the second run produces the `IDEMPOTENCY_VIOLATION` error message, which proves the script is not truly idempotent.
- **Success Condition Test**: The script must exit with a status code of `0`. The CI pipeline will fail any job where a script exits with a non-zero status.

## CI Process

- The GitHub Actions workflows in `/.github/workflows` are configured to call these scripts via their corresponding `make` targets.
- The `setup-installers.yml` and `setup-platform-tools.yml` workflows are specifically designed to test scripts from this directory.
- Any change to a script must pass the full CI pipeline, which includes the idempotency and success condition checks.

## Does Not Do

- Scripts in this directory do not handle user interaction. They must be fully non-interactive to run in CI environments.
- Scripts do not manage project-level dependencies. They are strictly for setting up the global development environment.
- Scripts do not alter system security settings, network configurations, or manage user data outside of their intended configuration scope (e.g., creating symlinks in `$HOME`).