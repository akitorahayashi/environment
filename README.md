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

**Interactive setup guide (recommended):**

```sh
# For MacBook
menv introduce macbook
# or shorthand:
menv itr mbk
menv itr mbk -nw  # Skip wait prompts

# For Mac mini
menv introduce mac-mini
# or shorthand:
menv itr mmn
```

The `introduce` command shows an interactive guide with commands you can run in parallel. Open multiple terminals to speed up setup.

**Design principle**: Most commands use the `common` profile by default (no profile argument needed). Only `brew-deps` and `brew-cask` require profile specification since they have machine-specific configurations.

menv provisions dotfiles by copying them into your home directory (no symlinks) so pipx upgrades won’t break paths.

**Run individual tasks:**

```sh
# List available tags
menv list
menv ls

# Run specific task (uses common profile by default)
menv make rust              # Run rust-platform + rust-tools
menv make go                # Run go-platform + go-tools
menv make python-tools      # Run python-tools
menv make shell             # Run shell setup
menv mk vscode              # Shorthand

# Profile required only for brew-deps and brew-cask
menv make brew-deps mbk     # Install brew dependencies for macbook
menv make brew-cask mmn     # Install GUI apps for mac-mini

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
menv config create --overlay # Overwrite existing configs with package defaults
menv cf set                 # Shorthand
menv cf cr rust -o          # Shorthand with overlay
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
menv introduce --help
menv make --help
```

## Development

### Setup

```sh
# Clone the repository
git clone https://github.com/akitorahayashi/menv.git
cd menv

# Install dependencies
uv sync
```

### Available Commands

```sh
# Run menv in development mode
just run --help
just run introduce macbook

# Run tests
just test

# Format and lint code
just fix
just check

# Clean temporary files
just clean
```

### Project Structure

```
menv/
├── src/menv/
│   ├── __init__.py
│   ├── __main__.py       # python -m menv
│   ├── main.py           # Typer app definition
│   ├── context.py        # AppContext (DI container)
│   ├── commands/
│   │   ├── backup.py     # backup/bk command
│   │   ├── config.py     # config/cf command
│   │   ├── introduce.py  # introduce/itr command (setup guide)
│   │   ├── make.py       # make/mk command (individual tasks)
│   │   ├── switch.py     # switch/sw command
│   │   └── update.py     # update/u command
│   ├── models/           # Data models (domain-grouped)
│   ├── services/         # Service implementations (1 class per file)
│   ├── protocols/        # Service protocols (1 per service)
│   └── ansible/          # Ansible playbooks and roles
│       ├── playbook.yml
│       └── roles/
├── tests/
│   └── mocks/            # Mock implementations (1 class per file)
├── justfile              # Development tasks
└── pyproject.toml
```

## Commands Summary

| Command | Alias | Description |
|---------|-------|-------------|
| `menv introduce <profile>` | `itr` | Interactive setup guide for a profile |
| `menv make <tag> [profile]` | `mk` | Run individual Ansible task |
| `menv list` | `ls` | List available tags |
| `menv backup <target>` | `bk` | Backup system settings |
| `menv config set` | `cf set` | Set VCS identities interactively |
| `menv config show` | `cf show` | Show current VCS identity configuration |
| `menv config create [role]` | `cf cr [role]` | Deploy role configs to ~/.config/menv/ |
| `menv switch <profile>` | `sw` | Switch VCS identity (personal/work) |
| `menv update` | `u` | Update menv to latest version |
