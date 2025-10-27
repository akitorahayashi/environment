# macOS Environment Setup

This repository contains the configuration and automation scripts to set up a consistent development environment on macOS using Ansible and Just.

## Overview

`menv` aims to automate the installation and configuration of development tools, shell environments, system settings, and application preferences for macOS. It uses Ansible for idempotency and Just as a command runner.

-   **Goal:** Provide a reproducible macOS development setup.
-   **Primary Tools:** Ansible, Just, Homebrew, Shell scripts, Python scripts.
-   **Documentation:** [Project Documentation Overview](./docs/overview.md)

## Installation

Detailed installation steps, including prerequisites like Xcode Command Line Tools and Homebrew, are available in the installation guide.

-   **Installation Guide:** [Installation](./docs/installation.md)

## Usage

The primary way to interact with this repository is through `make` (for initial bootstrap) and `just` (for managing specific setup tasks).

-   **Makefile Usage:** [Makefile Guide](./docs/makefile-usage.md)
-   **Just Command Runner:** [Justfile Guide](./docs/justfile-usage.md)
-   **`menv` Wrapper:** [menv Command Wrapper](./docs/menv-wrapper.md)

## Architecture

The setup logic is organized into Ansible roles, each managing a specific component of the environment.

-   **Ansible Roles Overview:** [Architecture](./docs/architecture.md)
-   **Role Details:**
    -   [`brew`](./docs/roles/brew.md) - Homebrew package management.
    -   [`shell`](./docs/roles/shell.md) - Zsh configuration and aliases.
    -   [`vcs`](./docs/roles/vcs.md) - Git and JJ configuration.
    -   [`gh`](./docs/roles/gh.md) - GitHub CLI setup.
    -   [`ssh`](./docs/roles/ssh.md) - SSH configuration.
    -   [`system`](./docs/roles/system.md) - macOS system defaults.
    -   [`ruby`](./docs/roles/ruby.md) - Ruby environment via rbenv.
    -   [`rust`](./docs/roles/rust.md) - Rust toolchain via rustup.
    -   [`editor`](./docs/roles/editor.md) - VS Code and Cursor setup.
    -   [`python`](./docs/roles/python.md) - Python environment via pyenv, uv, pipx, Aider.
    -   [`nodejs`](./docs/roles/nodejs.md) - Node.js environment via nvm, pnpm, LLM CLIs (Claude, Gemini, Codex).
    -   [`slash`](./docs/roles/slash.md) - AI slash command generation.
    -   [`docker`](./docs/roles/docker.md) - Docker image management.
    -   [`coderabbit`](./docs/roles/coderabbit.md) - CodeRabbit CLI setup.
    -   [`menv`](./docs/roles/menv.md) - `menv` command wrapper setup.

## Configuration

Environment-specific settings (like VCS user details) and tool configurations are managed through various files.

-   **Environment Variables:** [`.env` Configuration](./docs/configuration.md#environment-variables)
-   **Ansible Role Configuration:** [Role Configuration](./docs/configuration.md#ansible-roles)
-   **AI Agent Configuration:** [AI Tools](./docs/configuration.md#ai-tools)

## Development & Testing

Information on contributing, running linters, and executing tests.

-   **Development Guide:** [Development](./docs/development.md)
-   **Testing Strategy:** [Testing](./docs/testing.md)
-   **CI Workflows:** [CI Workflows](./docs/ci-workflows.md)
