# Usage

The core environment setup executes via:

```sh
mev create macbook        # Full MacBook setup
mev create mac-mini       # Full Mac mini setup
mev cr mbk                # Shorthand
mev cr mbk -v             # Verbose output
mev cr mbk --overwrite    # Force overwrite role configs
```

Individual tasks execute via:

```sh
mev list                  # List available tags
mev ls                    # Shorthand

mev make rust             # Run rust-platform + rust-tools
mev make go               # Run go-platform + go-tools
mev make python-tools     # Run python-tools
mev make shell --overwrite # Force overwrite configs
mev mk vscode             # Shorthand

# Profile required for brew tasks
mev make br-f --profile mbk
mev make br-c --profile mmn

# Tag groups expand automatically:
#   rust → rust-platform, rust-tools
#   go → go-platform, go-tools
#   python → python-platform, python-tools
#   nodejs → nodejs-platform, nodejs-tools
```

Configuration deploys via:

```sh
mev identity set          # Configure Git identities interactively
mev identity show         # Show current configuration
mev id show               # Shorthand
mev config deploy         # Deploy all role configs to ~/.config/mev/roles/
mev cf dp                 # Shorthand
mev config deploy rust    # Deploy only rust role config
```

Git identity switches via:

```sh
mev switch personal       # Switch to personal identity
mev switch work           # Switch to work identity
mev sw p                  # Shorthand
mev sw w                  # Shorthand
```

Backup initiates via:

```sh
mev backup system         # Backup macOS system defaults
mev backup vscode         # Backup VSCode extensions list and settings.json
mev backup --list         # List available backup components
mev backup -l             # Short flag
mev bk system             # Shorthand
```

Update executes via:

```sh
mev update
mev u                     # Shorthand
```

Help displays via:

```sh
mev --help
mev make --help
```
