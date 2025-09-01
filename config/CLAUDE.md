## CLAUDE.md Self-Modification Obligation

**Important**: This document governs the behavior of the claudecode agent itself. When changes are made to the codebase (adding new configuration files, changing the directory structure, etc.), claudecode is obligated to update this `CLAUDE.md` as part of the transaction to maintain consistency between the documentation and the implementation.

## Module Roles and Responsibilities

This `config` directory serves as the centralized store for all configuration data used by the automation scripts. Its primary role is to decouple the setup logic (in `/scripts`) from the setup data (here). It defines *what* to install and configure, while the scripts define *how* to do it. This directory must contain all user-tunable settings, version numbers, package lists, and dotfiles.

## Technology Stack and Environment

This directory manages configurations for a variety of tools and formats. You must use the correct format for each file type.

- **Homebrew**: `Brewfile` format.
- **Git**: `.gitconfig` and `.gitignore_global` INI-like format.
- **GitHub CLI**: `config.yml` in YAML format.
- **Node.js**: `.nvmrc` for version, `global-packages.json` for packages.
- **Python**: `.python-version` for version, `pipx-tools.txt` for tools.
- **Ruby**: `.ruby-version` for version, `global-gems.rb` for gems.
- **Shell**: `.zprofile` and `.zshrc` (Zsh shell script format).
- **VS Code**: `settings.json`, `keybindings.json`, `extensions.txt`.
- **macOS Defaults**: `system-defaults.sh` (a shell script of `defaults write` commands).

## Architectural Principles and File Structure

The configuration architecture is based on a layered model to support multiple machine types. Adhere strictly to this structure.

1.  **`common/` Directory**:
    - This is the base layer. Place all configurations that are shared across every machine in this directory.
    - The file structure within `common/` must be organized by tool (e.g., `common/brew/Brewfile`, `common/python/.python-version`).

2.  **`macbook-only/` and `mac-mini-only/` Directories**:
    - These directories contain configurations specific to a particular machine type.
    - The scripts are designed to apply the `common` configuration first, and then the machine-specific configuration.
    - Use these directories only for settings that are additive to or override the `common` configuration. For example, `macbook-only/brew/Brewfile` contains Casks only needed on a MacBook.
    - Never duplicate a configuration file from `common/` unless you intend to completely replace it for that specific machine.

3.  **Adding a New Tool**:
    - To add configuration for a new tool, first create a new subdirectory under `config/common/` (e.g., `config/common/newtool/`).
    - Place the tool's configuration files within that new directory.
    - If the tool requires machine-specific settings, create a corresponding subdirectory in `config/macbook-only/` or `config/mac-mini-only/`.

## Coding Standards and Style Guide

- **Version Files (`.python-version`, `.ruby-version`, `.nvmrc`)**: Must contain only the version string and a single trailing newline. Never add comments or other text.
- **Package Lists (`Brewfile`, `pipx-tools.txt`, `global-packages.json`)**:
    - List one package per line.
    - Keep the lists alphabetized where the format allows, to avoid merge conflicts and improve readability.
    - In `Brewfile`, add comments to group related packages (e.g., `## Development Tools`).
- **JSON Files (`settings.json`, `keybindings.json`)**: Must be well-formed JSON. Use a consistent indentation of two spaces.
- **Dotfiles (`.zshrc`, `.gitconfig`)**:
    - Group related aliases or settings together with comment headers.
    - Keep the configuration clean and focused on defining settings, not complex logic.

## Critical Business Logic and Invariants

- **Separation of Concerns**: This directory must only contain data and configuration. It must never contain executable logic beyond what is required by the configuration file format itself (e.g., simple shell commands in `.zshrc`). All complex logic belongs in the `/scripts` directory.
- **Single Source of Truth**: For any given tool, its version or package list must be defined in exactly one place within the appropriate configuration file. Scripts must always read from these files. Never hardcode versions or package names in the scripts.
- **Layering Precedence**: The setup process always applies `common` configurations before machine-specific ones. This means machine-specific settings will always take precedence if there is an overlap. Be aware of this when modifying files.

## Testing Strategy and Procedures

- The validity of these configuration files is tested indirectly by the CI process. When a script in the CI pipeline (e.g., `make python-platform`) is executed, it consumes files from this directory.
- A test failure in a script often indicates a problem with the corresponding configuration file (e.g., syntax error, incorrect version format, non-existent package).
- Therefore, when a script fails, always validate the correctness of the configuration file it depends on. For example, if the `homebrew.sh` script fails, check the syntax of the corresponding `Brewfile`.

## CI Process

- The CI pipeline defined in `.github/workflows/` uses these configuration files to run the setup on a fresh macOS runner.
- The `setup-homebrew` workflow specifically validates that the packages listed in the `Brewfile`s are available from Homebrew.
- Any modification, addition, or deletion of a configuration file in this directory must pass the full CI pipeline to ensure it doesn't break the setup process for any machine type.

## Does Not Do

- This directory does not store runtime state, caches, or temporary files.
- It does not contain user-specific secrets (e.g., API keys). The only exception is the `.env` file at the root, which is git-ignored and sourced from `.env.example`, for Git user credentials. Never commit secrets to any file within the `config` directory.