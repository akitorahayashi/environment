# mev - macOS Environment Setup Project

## Overview

Rust-first CLI for macOS dev environment setup using bundled Ansible playbooks.
Installable as a standalone Rust binary via `install.sh`.

## Routing

For detailed work and architectural guidelines, agents use the following as their primary sources of truth:
- [Contributing](CONTRIBUTING.md): Workflow, coding standards, and procedural verification rules.
- [Docs](docs/): The central index for architectural decisions, system usage, and configuration specifications.

The CLI commands are detailed in [Docs Usage](docs/usage.md).

## Python Surface

Python ownership is limited to development tooling (`ansible-lint`) managed by `pyproject.toml`.
Runtime command ownership belongs to the Rust implementation.
