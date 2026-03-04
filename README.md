# mev

macOS development environment provisioning CLI.

Rust-first architecture with a thin Python launcher for `pipx` distribution.

## Quick Start

### Prerequisites

1. Xcode Command Line Tools
   ```sh
   xcode-select --install
   ```

2. Homebrew
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
   Restart your terminal after installation.

3. uv & pipx
   ```sh
   brew install uv pipx
   pipx ensurepath
   ```
   Restart your terminal after installation.

### Installation

```sh
pipx install git+https://github.com/akitorahayashi/mev.git
```

### Usage

Core environment setup:

```sh
mev create macbook        # Full MacBook setup
mev create mac-mini       # Full Mac mini setup
mev cr mbk                # Shorthand
mev cr mbk -v             # Verbose output
mev cr mbk --overwrite    # Force overwrite role configs
```

Run individual tasks:

```sh
mev list                  # List available tags
mev ls                    # Shorthand

mev make rust             # Run rust-platform + rust-tools
mev make go               # Run go-platform + go-tools
mev make python-tools     # Run python-tools
mev make shell --overwrite # Force overwrite configs
mev mk vscode             # Shorthand

# Profile required for brew tasks
mev make brew-formulae mbk
mev make brew-cask mmn

# Tag groups expand automatically:
#   rust → rust-platform, rust-tools
#   go → go-platform, go-tools
#   python → python-platform, python-tools
#   nodejs → nodejs-platform, nodejs-tools
```

Configuration:

```sh
mev config set            # Configure VCS identities interactively
mev config show           # Show current configuration
mev config create         # Deploy all role configs to ~/.config/mev/
mev config create rust    # Deploy only rust role config
mev cf set                # Shorthand
```

Switch VCS identity:

```sh
mev switch personal       # Switch to personal identity
mev switch work           # Switch to work identity
mev sw p                  # Shorthand
mev sw w                  # Shorthand
```

Backup:

```sh
mev backup system         # Backup macOS system defaults
mev backup vscode         # Backup VSCode extensions list
mev backup list           # List available backup targets
mev bk system             # Shorthand
```

Update:

```sh
mev update
mev u                     # Shorthand
```

Help:

```sh
mev --help
mev make --help
```
