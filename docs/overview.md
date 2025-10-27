# Overview

`menv` automates a complete macOS development workstation so the same tooling, editor setup, and system preferences can be reproduced on every machine. The automation centers on Ansible for idempotent configuration and Just for orchestration, with supporting Python and shell utilities.

## Goals
- Provision a ready-to-work macOS environment with minimal manual input.
- Keep personal and work profiles in sync while allowing machine-specific overrides.
- Encapsulate tooling choices—CLI utilities, programming languages, editors, AI agents—inside repeatable roles.
- Remain portable by avoiding hard-coded paths and relying on symlinks owned by the automation.

## Core Toolchain
- **Ansible** applies roles that configure Homebrew, languages, editors, AI CLIs, dotfiles, and system defaults.
- **Just** exposes ergonomic recipes that select Ansible tags, run tests, and manage backups.
- **Homebrew** delivers platform packages and casks, backed by profile-aware Brewfiles.
- **Python + uv + pipx** power helper scripts, dependency management, and virtual environments.
- **Shell (Zsh)** plus curated aliases and scripts expose the automation at runtime.
- **AI & CLI Utilities** such as Claude, Gemini, Codex, slash commands, Aider, and CodeRabbit are integrated as first-class tools.

## Where to Start
Refer to the [Architecture](./architecture.md) document to understand how the Makefile, Just recipes, and Ansible roles interact. Installation instructions, day-to-day commands, and detailed role documentation live alongside this overview within the `docs/` tree.
