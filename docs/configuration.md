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
The system role uses `src/assets/ansible/roles/system/config/global/default_apps.yml` to declare default applications grouped by application bundle identifier.

### System Default Applications

Filename extensions are declared without a leading dot under each application's `extensions` list. Each application handles all LaunchServices roles for its declared extensions.
The bundled collection provides a conservative default set: `Zed` for source and config files, `Google Chrome` for browser-oriented HTML files, and `Preview` for common document and image formats.

```yaml
---
default_apps:
  - bundle_id: dev.zed.Zed
    extensions:
      - md
  - bundle_id: com.google.Chrome
    extensions:
      - html
  - bundle_id: com.apple.Preview
    extensions:
      - pdf
```

## Release

`v*` tag push: `.github/workflows/release.yml` delegates to `.github/workflows/build.yml`, and the build job attaches `mev-darwin-aarch64` plus its SHA256 file directly to GitHub Releases
