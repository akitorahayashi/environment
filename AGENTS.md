# Environment Setup Project

## Project Overview
A comprehensive automation project for setting up consistent macOS development environments across different machines (MacBook and Mac mini). This project uses Ansible playbooks to automate the installation and configuration of development tools, system settings, and environment configurations.

## Quick Start Guide

### Entry Points
1. **`Makefile`** - Initial setup entry point (you should not execute)
   - `make base`: Installs Homebrew, Just, and Ansible
   - `make macbook` / `make mac-mini`: Runs full machine-specific setup

2. **`justfile`** - Individual task runner and command orchestrator
   - Individual component setup commands (`just cmn-*`, `just mbk-*`, `just mmn-*`)
   - Profile switching (`just sw-p` / `just sw-w`)
   - Backup utilities (`just cmn-backup-*`)
   - Role additions and customizations

3. **`README.md`** - Comprehensive project documentation
   - Directory structure and architecture explanation
   - Usage instructions and command reference
   - Detailed Ansible role functionality

## Design Rules

### Configuration Path Resolution
**Core Principle**: justfile passes only profile name and base paths; Ansible roles handle all path resolution and fallback logic.

**Rules**:
- **justfile**: Pass `profile`, `config_dir_abs_path`, and `repo_root_path` only
- **Common configs**: Use `{{config_dir_abs_path}}` (e.g., `{{config_dir_abs_path}}/vcs/git/.gitconfig`)
- **Profile configs**: Use `{{repo_root_path}}/config/profiles/{{profile}}` (e.g., `{{repo_root_path}}/config/profiles/{{profile}}/apps/Brewfile`)
- **Fallback logic**: Roles must implement profile-specific → common fallback for optional overrides
- **No hardcoded paths**: Avoid embedding specific config subdirectories in justfile