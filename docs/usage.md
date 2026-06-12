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

mev make rust             # Install and configure the Rust toolchain
mev mk sh sys pipx -o     # Sequential execution (stops on error)
mev make rust-cli         # Install Rust CLI binaries from GitHub Releases
mev make bun              # Run Bun setup and global packages
mev make b                # Shorthand
mev make nodejs           # Install and configure the Node.js runtime
mev make pnpm             # Configure pnpm and install global packages
mev make python           # Install and configure uv-managed Python
mev make pipx             # Install Python applications with pipx
mev make coder            # Install and configure coding agent CLIs
mev make system           # Apply macOS defaults
mev make duti             # Apply LaunchServices file associations explicitly
mev make shell --overwrite # Force overwrite configs
mev mk vscode             # Shorthand
mev make agi              # Shorthand for Antigravity IDE
mev make desktop          # Install required editor/terminal casks, then configure them

# Hardware profile behavior for brew tasks
mev make br-f             # Run global formulae
mev make br-c             # Run global casks
mev make br-f -p mbk      # Run global formulae with the MacBook profile
mev make br-c -p mmn      # Run global casks + Mac mini casks

# Tag groups expand automatically:
#   bun → bun
#   desktop → vscode, antigravity-ide, zed, ghostty
```

Configuration deploys via:

```sh
mev identity set          # Configure Git identities interactively
mev identity show         # Show current configuration
mev id show               # Shorthand
mev config deploy         # Deploy all role configs to ~/.config/mev/roles/
mev cf dp                 # Shorthand
mev config deploy rust    # Deploy only rust role config
mev config deploy rust-cli # Deploy only rust-cli role config
mev config deploy bun     # Deploy only bun role config
mev config deploy pnpm    # Deploy only pnpm role config
mev config deploy pipx    # Deploy only pipx role config
mev config deploy coder   # Deploy only coding agent config
mev config deploy editor/vscode # Deploy only VS Code config
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
mev backup agi            # Backup Antigravity IDE extensions list and settings
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
