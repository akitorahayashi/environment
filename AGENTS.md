# mev - macOS Environment Setup Project

## Overview

Rust-first CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.

## Routing

For detailed work and architectural guidelines, agents must use the following as their primary sources of truth:
- [Contributing](CONTRIBUTING.md): Workflow, coding standards, and procedural verification rules.
- [Docs](docs/): The central index for architectural decisions, system usage, and configuration specifications.

## CLI Commands

See [README.md](README.md) for the list of available commands and usage instructions.

## Python Surface

Python ownership is limited to development tooling (`ansible-lint`) managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.
