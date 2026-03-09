# Quick Start

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

### Distribution Binary Synchronization

`dist/mev/bin/darwin-aarch64/mev` is synchronized on pushes to `main` by `.github/workflows/sync-bundled-binary.yml`.
