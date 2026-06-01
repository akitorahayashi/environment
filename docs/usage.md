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
mev make bun              # Run bun-platform + bun-tools
mev make bun-platform     # Run bun-platform only
mev make b-p              # Shorthand
mev make bun-tools        # Run bun-tools only
mev make b-t              # Shorthand
mev make python-tools     # Run python-tools
mev make shell --overwrite # Force overwrite configs
mev mk vscode             # Shorthand
mev make desktop          # Install required editor/terminal casks, then configure them

# Hardware profile behavior for brew tasks
mev make br-f             # Run global formulae
mev make br-c             # Run global casks
mev make br-f -p mbk      # Run global formulae with the MacBook profile
mev make br-c -p mmn      # Run global casks + Mac mini casks

# Tag groups expand automatically:
#   rust → rust-platform, rust-tools
#   go → go-platform, go-tools
#   python → python-platform, python-tools
#   nodejs → nodejs-platform, nodejs-tools
#   bun → bun-platform, bun-tools
```

Configuration deploys via:

```sh
mev identity set          # Configure Git identities interactively
mev identity show         # Show current configuration
mev id show               # Shorthand
mev config deploy         # Deploy all role configs to ~/.config/mev/roles/
mev cf dp                 # Shorthand
mev config deploy rust    # Deploy only rust role config
mev config deploy bun     # Deploy only bun role config
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
