# Configuration

## Files

| File | Purpose |
|------|---------|
| `Cargo.toml` | Rust package metadata and dependencies |
| `clippy.toml` | Clippy linter configuration |
| `rustfmt.toml` | Rust formatter configuration |
| `rust-toolchain.toml` | Rust toolchain version pinning |
| `mise.toml` | Development tool version management |
| `pyproject.toml` | Development Python dependency groups (`ansible-lint`) |
| `justfile` | Development task automation |

## Ansible Role Configs

Role-specific provisioning data lives under `src/assets/ansible/roles/<role>/config/global/`.
The Bun role uses `src/assets/ansible/roles/bun/config/global/global-packages.json` to declare Bun global packages.
The pnpm role uses `src/assets/ansible/roles/pnpm/config/global/global-packages.json` to declare global packages.
The pipx role uses `src/assets/ansible/roles/pipx/config/global/tools.yml` to declare isolated Python applications by `package`, with optional `version`, `install_spec`, `inject`, and `post_install.argv` fields.
The rust-cli role uses `src/assets/ansible/roles/rust_cli/config/global/tools.yml` to declare GitHub Release binaries.
The Coder role stores each tool's configuration under its tool name and uses the deployed file's actual name.

## Release

`v*` tag push: `.github/workflows/release.yml` delegates to `.github/workflows/build.yml`, and the build job attaches `mev-darwin-aarch64` plus its SHA256 file directly to GitHub Releases
