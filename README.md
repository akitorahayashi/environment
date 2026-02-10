# menv

macOS development environment provisioning CLI.

## Quick Start

### Prerequisites

1. **Xcode Command Line Tools**
   ```sh
   xcode-select --install
   ```

2. **Homebrew**
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   Restart your terminal after installation.

3. **pipx**
   ```sh
   brew install pipx
   pipx ensurepath
   ```
   Restart your terminal after installation.

### Installation

```sh
pipx install git+https://github.com/akitorahayashi/menv.git
```

### Usage

**Core environment setup (recommended):**

```sh
# For MacBook
menv create macbook
# or shorthand:
menv cr mbk
menv cr mbk -v  # Verbose output

# For Mac mini
menv create mac-mini
# or shorthand:
menv cr mmn
```

The `create` command runs core setup tasks in the correct order to provision a base macOS development environment. It stops immediately on any failure, making it easy to identify and fix issues.

**Design principle**: Most commands use the `common` profile by default (no profile argument needed). `brew-formulae` and `brew-cask` prioritize profile-specific configurations but fallback to `common` if not found.

menv provisions dotfiles by symlinking them into your home directory.

**Run individual tasks:**

```sh
# List available tags
menv list
menv ls

# Run specific task (uses common profile by default)
menv make rust              # Run rust-platform + rust-tools
menv make go                # Run go-platform + go-tools
menv make python-tools      # Run python-tools
menv make shell --overwrite   # Force overwrite existing configs
menv mk vscode              # Shorthand

# Editors
menv make vscode            # Setup VS Code (config symlinks + extensions)
menv make cursor            # Setup Cursor (config symlinks + extensions)
menv make antigravity       # Setup Google Antigravity (config symlinks + extensions + agent skills)
                            # Agent skills are sourced from coder SSOT (requires 'menv make coder' first)

# LLM infrastructure (local models)
menv make ollama            # Setup Ollama only
menv make mlx               # Setup MLX venv only
menv make ollama-models     # Download Ollama models (requires ollama serve)
menv make mlx-models        # Download MLX models

# Coder tools (cloud LLM CLI tools)
menv make coder             # Install Claude, Gemini, Codex CLI tools
                            # Deploy shared Agent Skills (SSOT) to tool directories
                            # Skills deployed to: ~/.codex/skills, ~/.claude/skills, ~/.gemini/skills, ~/.config/google/antigravity/skills
                            # Source of truth: ~/.config/menv/roles/nodejs/common/coder/skills

# Profile required only for brew-formulae and brew-cask
menv make brew-formulae mbk     # Install brew dependencies for macbook
menv make brew-cask mmn     # Install GUI apps for mac-mini
menv make brew-formulae mbk -o  # Force overwrite configs

# Tag groups are expanded automatically:
#   rust → rust-platform, rust-tools
#   go → go-platform, go-tools
#   python → python-platform, python-tools
#   nodejs → nodejs-platform, nodejs-tools
```

**Backup commands:**

```sh
menv backup system          # Backup macOS defaults
menv backup vscode          # Backup VSCode extensions
menv bk system              # Shorthand
```

**Configuration:**

```sh
menv config set             # Configure VCS identities interactively
menv config show            # Show current configuration
menv config create          # Deploy all role configs to ~/.config/menv/
menv config create rust     # Deploy only rust role config
menv config create --overwrite # Overwrite existing configs with package defaults
menv cf set                 # Shorthand
menv cf cr rust -o          # Shorthand with overwrite
```

**Switch VCS identity:**

```sh
menv switch personal        # Switch to personal identity
menv switch work            # Switch to work identity
menv sw p                   # Shorthand for personal
menv sw w                   # Shorthand for work
```

**Update menv:**

```sh
menv update
# or shorthand:
menv u
```

**Show help:**

```sh
menv --help
menv make --help
```

**Create environment with overwrite:**

```sh
menv create macbook --overwrite  # Force overwrite all configs during setup
menv cr mbk -o                 # Shorthand with overwrite
```

**Shell Aliases:**

`menv` provides several useful aliases via the `shell` role.

**Aider (AI Pair Programmer)**

| Alias | Command | Description |
|-------|---------|-------------|
| `ai` | `menv internal aider run` | Run aider on specified files/dirs |
| `ai-st <model>` | `menv internal aider set-model` | Set default Ollama model for aider |
| `ai-ls` | `menv internal aider list-models` | List available Ollama models |
| `ai-us` | `menv internal aider unset-model` | Unset default model |

**Context Management**

| Alias | Description |
|-------|-------------|
| `cld-ln` | Symlinks `AGENTS.md` (priority) or `README.md` to `.claude/CLAUDE.md` for Claude CLI context. |
