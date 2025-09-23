# Environment Setup Project

## Project Overview
A comprehensive automation project for setting up consistent macOS development environments across different machines (MacBook and Mac mini). This project uses Ansible playbooks to automate the installation and configuration of development tools, system settings, and environment configurations.

## Tech Stack

### Core Technologies
- **Automation**: Ansible for orchestration and idempotent configuration management
- **Task Runner**: Just command runner for recipe management
- **Build Tool**: Make for initial bootstrap setup
- **Package Manager**: Homebrew for system packages and applications
- **Version Control**: Git with GitHub CLI integration

### Development Tools
- **Python**: pyenv for version management, pipx for isolated tool installation
  - Primary tools: uv, jupyterlab
- **Node.js**: nvm for version management, pnpm for package management
  - Global packages: @google/gemini-cli, @anthropic-ai/claude-code, @marp-team/marp-cli, md-to-pdf
- **Ruby**: rbenv for version management
- **Java**: Temurin JDK 21
- **Go**: Latest version via Homebrew
- **Shell**: Zsh with custom configuration and aliases

### AI Development Tools
- **Claude Code**: AI-powered development assistant with MCP servers
- **Gemini CLI**: Google's AI development tools
- **MCP Servers**: Context7, Serena, VOICEVOX for enhanced AI capabilities

### Editors and IDEs
- **Visual Studio Code**: Primary editor with extensions and settings synchronization
- **Cursor**: AI-enhanced editor with shared VSCode configuration

## Code Styling

### General Conventions
- **Format on Save**: Enabled in VSCode and Cursor configurations
- **Documentation**: English for all development-related documentation
- **Communication**: Japanese for user interaction, English for code/docs
- **File Organization**: Structured configuration directories with platform-specific overrides

### Shell Scripting
- Consistent alias patterns using helper functions
- Modular configuration split across `.zsh/` files
- Environment variable management through `.env` files

### Configuration Management
- YAML for Ansible playbooks and system definitions
- JSON for package manifests and tool configurations
- Symbolic linking for shared configurations between tools

## Naming Conventions

### Directory Structure
- `config/common/`: Shared configurations across all machines
- `config/macbook-only/`: MacBook-specific configurations
- `config/mac-mini-only/`: Mac mini-specific configurations
- `ansible/roles/`: Modular Ansible roles for each component

### Command Aliases
- **Development shortcuts**: `${prefix}-${action}` pattern (e.g., `j-t` for `just test`)
- **Testing variants**: Specific test type suffixes (`-ut`, `-et`, `-it` for unit, e2e, integration tests)
- **Format and lint**: Combined operations (`-fl` for format then lint)

### File Naming
- Configuration files use lowercase with hyphens
- Ansible files follow role-based organization
- Global packages use semantic versioning ("latest" for consistency)

## Development Commands

### Bootstrap Setup
```bash
make base          # Install Xcode tools, Homebrew, Ansible, Just
```

### Platform-Specific Setup
```bash
make macbook       # Full MacBook environment setup
make mac-mini      # Full Mac mini environment setup
```

### Individual Component Setup
```bash
just cmn-shell     # Shell configuration
just cmn-vscode    # VSCode setup
just cmn-python-platform # Python environment
just cmn-nodejs-platform # Node.js environment
just cmn-claude    # Claude Code configuration
just cmn-gemini    # Gemini CLI setup
```

### Maintenance Commands
```bash
just cmn-backup-system           # Backup macOS system settings
just cmn-backup-vscode-extensions # Backup VSCode extensions
just cmn-apps                    # Install GUI applications
just cmn-docker-images          # Pull Docker images
```

## Testing Strategy

### Test Command Discovery
The project includes intelligent test command discovery through the `tst` command that:
1. Accepts full commands (e.g., `make e2e-test`) or test types (e.g., `unit`, `e2e`)
2. Searches for common patterns: `make $1-test`, `npm run test:$1`, `pytest tests/$1/`
3. Examines project files (package.json, Makefile, justfile) for test scripts

### Test Execution Flow
1. Execute the discovered test command
2. Analyze test results and failures
3. Apply appropriate fixes (test code or implementation)
4. Re-run tests until all pass
5. Ensure implementation remains clean and maintainable

### Testing Tools Integration
- **Python**: pytest with aliases and cache management
- **Django**: Built-in test runner integration
- **Generic**: Flexible test command patterns for various frameworks
- **CI/CD**: GitHub Actions integration through gh CLI

### Test Types Supported
- Unit tests (`-ut`)
- UI tests (`-uit`)
- End-to-end tests (`-et`)
- Integration tests (`-it`)
- Performance tests (`-pet`)
- Build tests (`-bt`)
- Database tests (`-sqt`, `-pst`)

## Environment Variables
Required environment variables (defined in `.env`):
- `GIT_USERNAME`: Git configuration
- `GIT_EMAIL`: Git configuration
- `GITHUB_PERSONAL_ACCESS_TOKEN`: GitHub CLI and MCP server authentication
- `OBSIDIAN_API_KEY`: Obsidian MCP server integration