# Rust Tools Installation

The rust role downloads pre-built binaries from GitHub releases rather than compiling via cargo.

**Configuration files:**
- `config/common/tools.yml`: List of tools with name, repo (owner/name), and tag
- `config/common/platforms.yml`: OS and architecture mapping for asset names

**Installation process:**
1. Check installed version via `<tool> --version`
2. Download binary from `https://github.com/<repo>/releases/download/<tag>/<name>-<os>-<arch>`
3. Install to `~/.cargo/bin/` with executable permissions

**Tools included:** gho, jlo, kpv, mx, pure, ssv

**Asset naming convention:** `<binary>-<os>-<arch>` (e.g., `mx-darwin-aarch64`)
