# mev

macOS development environment provisioning CLI.

Rust-first architecture with embedded Ansible assets (playbooks and roles), orchestrating an external `ansible-playbook` binary installed on the host via `pipx`.

## Quick Start

### Prerequisites

The following prerequisites are required:

1. Xcode Command Line Tools
   ```sh
   xcode-select --install
   ```
2. Homebrew
   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
3. pipx
   ```sh
   brew install pipx
   pipx ensurepath
   ```
4. ansible (via pipx)
   ```sh
   pipx install ansible
   ```

### Installation

The CLI is installed via the following script:

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/akitorahayashi/mev/main/install.sh)"
```

### Verification

The installation is verified via:

```sh
mev --version
mev list
```

## Documentation

- [Docs](docs/README.md): Central index for usage guides, configuration references, and environment setup.
- [Contributing](CONTRIBUTING.md): Development guidelines, coding standards, and testing procedures for contributors.
- [Agents](AGENTS.md): Routing to workflow and docs for LLM agents.
