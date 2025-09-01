## CLAUDE.md Self-Modification Obligation

**Important**: This document governs the behavior of the claudecode agent itself. When CI/CD processes are changed (e.g., adding a new workflow, modifying a job's logic), claudecode is obligated to update this `CLAUDE.md` as part of the transaction to reflect the new pipeline architecture and testing strategies.

## Module Roles and Responsibilities

This directory, `.github/workflows`, is responsible for the project's Continuous Integration (CI) pipeline. Its sole purpose is to automatically test the macOS environment setup scripts and configurations to ensure they are correct, reliable, and idempotent. It acts as the gatekeeper for quality, preventing broken or non-idempotent changes from being merged into the `main` branch.

## Technology Stack and Environment

- **CI/CD Platform**: GitHub Actions.
- **Workflow Language**: YAML. All workflows must be written in valid YAML syntax.
- **Runner Environment**: All jobs must run on `macos-15` to accurately simulate the target user environment.
- **Execution Engine**: Workflows must use `make` to execute setup tasks, respecting the project's architectural decision to use the `Makefile` as the primary entry point.

## Architectural Principles and File Structure

The CI pipeline is designed with modularity and reusability in mind. You must adhere to this structure.

1.  **`ci-pipeline.yml`**:
    - This is the main, user-facing workflow that is triggered on pushes and pull requests to the `main` branch.
    - Its only role is to orchestrate the execution of other, reusable workflows. It must not contain any complex job logic itself.

2.  **Reusable Workflows (`setup-*.yml`)**:
    - All testing logic must be encapsulated within reusable workflows that are triggered via `on: workflow_call`.
    - Each reusable workflow must be responsible for testing a specific, logical component of the setup (e.g., `setup-homebrew.yml`, `setup-installers.yml`, `setup-platform-tools.yml`).
    - This architecture ensures that testing logic is DRY (Don't Repeat Yourself) and easy to maintain.

3.  **Job and Step Naming**:
    - All workflows, jobs, and steps must have clear, descriptive `name` attributes. This is crucial for understanding the pipeline's execution flow in the GitHub UI.

4.  **Matrix Strategy**:
    - When testing multiple similar components (e.g., installers for `git`, `gh`, `ruby`), you must use a `strategy: matrix` to run these tests in parallel. This improves the efficiency of the CI pipeline.

## Coding Standards and Style Guide

- **YAML Formatting**: Use two spaces for indentation.
- **Actions Versioning**: Pin GitHub Actions to a specific major version (e.g., `actions/checkout@v4`) to ensure stability. Do not use floating tags like `@latest`.
- **Idempotency Check Implementation**: The idempotency test is a critical pattern that must be implemented consistently. The required sequence is:
    1.  Run the target `make` command once to perform the setup.
    2.  Run the exact same `make` command a second time.
    3.  Redirect `stdout` of the second run to `/dev/null` but capture `stderr`.
    4.  Check if the captured `stderr` contains the string `IDEMPOTENCY_VIOLATION`.
    5.  Fail the job if the string is found.

## Critical Business Logic and Invariants

- **Idempotency is the Core Requirement**: The most critical function of this CI pipeline is to enforce the idempotency of all setup scripts. A passing build is a guarantee that the scripts can be run multiple times safely.
- **CI is the Source of Truth**: A successful CI run is the definitive measure of a change's correctness. All changes must pass the full CI pipeline before being considered complete.
- **Environment Consistency**: The CI environment (`macos-15` runner) must be kept as close as possible to the target user environment to ensure the validity of the tests.

## Testing Strategy and Procedures

- **Scope of Testing**: The CI tests the end-to-end execution of each `make` target. It does not perform unit tests on individual shell functions.
- **Primary Test Case**: The primary test case for any setup script is the **idempotency test** as described in the "Coding Standards" section.
- **Secondary Test Case**: All scripts must run to completion and exit with a status code of `0`. The workflow will automatically fail any job where a step has a non-zero exit code.

## CI Process

- **Trigger**: The `ci-pipeline.yml` workflow is automatically triggered on `push` and `pull_request` events targeting the `main` branch. It can also be triggered manually via `workflow_dispatch`.
- **Execution Flow**:
    1.  `ci-pipeline.yml` starts.
    2.  It calls multiple reusable workflows in parallel.
    3.  Each reusable workflow runs one or more jobs, often using a matrix strategy.
    4.  Each job checks out the code, sets up any necessary authentication (e.g., for Homebrew), and executes the `make` targets.
    5.  The idempotency and success/failure of each job are reported back to the main workflow.
    6.  The entire run is considered successful only if all orchestrated jobs in all reusable workflows pass.

## Does Not Do

- This CI pipeline does not build or deploy any artifacts. Its sole purpose is testing.
- It does not run on any operating system other than macOS.
- It does not perform security scanning, code linting (other than what might be in a `Makefile` target), or performance testing.