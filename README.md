# mev

macOS development environment provisioning CLI.

Rust-first architecture with embedded Ansible assets.

## Canonical Model

- Profile: A machine hardware configuration target (e.g., Macbook, MacMini, Common) mapped to an Ansible execution context.
- Identity: Personal or work VCS configuration elements (name, email) applied to Git and Jujutsu.
- Tag: An individual provisioning task or group of tasks resolved into an execution plan.
- Backup Target: A defined system state or application configuration (e.g., macOS defaults, VSCode extensions) preserved by the tool.

## Prerequisites

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

## Installation

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/akitorahayashi/mev/main/install.sh)"
```

## Verification

```sh
mev --version
mev list
```

## Documentation

- [Docs](docs/README.md): Central index for usage guides, configuration references, and environment setup.
- [Contributing](CONTRIBUTING.md): Development guidelines, coding standards, and testing procedures for contributors.
- [Agents](AGENTS.md): Routing to workflow and docs for LLM agents.
