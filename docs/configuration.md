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
Category directories contain related roles without owning tasks, tags, or configs. Editor roles live under `src/assets/ansible/roles/editor/<editor>/`.
The Bun role uses `src/assets/ansible/roles/bun/config/global/global-packages.json` to declare Bun global packages.
The pnpm role uses `src/assets/ansible/roles/pnpm/config/global/global-packages.json` to declare global packages.
The pipx role uses `src/assets/ansible/roles/pipx/config/global/tools.yml` to declare isolated Python applications by `package`, with optional `version`, `install_spec`, `inject`, and `post_install.argv` fields.
The rust-cli role uses `src/assets/ansible/roles/rust_cli/config/global/tools.yml` to declare GitHub Release binaries.
The Coder role stores each tool's configuration under its tool name and uses the deployed file's actual name.
The Coder role stores AGENTS.md as per-section files under `config/global/agents-sections/<name>.md` with `catalog.yml` declaring section order and existence. mev concatenates the enabled sections into the intermediate `~/.config/mev/coder/AGENTS.md`, and the role symlinks each agent tool's instruction file to that intermediate.
The Coder role stores agent skills once under `config/global/skills/<name>/`. mev links each enabled skill into the intermediate `~/.config/mev/coder/skills/`, and the role deploys those entries to the interoperable `~/.agents/skills/` location plus the tool-specific locations required by Claude Code and Antigravity.
mev keeps coder generated entities under `~/.config/mev/coder/`, separate from the `~/.config/mev/roles/` deployment tree so re-deploying coder sources never overwrites them.
`mev config select agents` and `mev config select skills` record disabled entries in `~/.config/mev/coder/agents-sections.yml` and `~/.config/mev/coder/skills-selection.yml`. Entries absent from the disabled list stay enabled, so catalog additions in a later mev version are enabled by default; disabled names no longer present in the catalog are ignored with a warning.
The duti role uses `src/assets/ansible/roles/duti/config/global/default_apps.yml` to declare default applications grouped by bundle identifier.
The system role uses `src/assets/ansible/roles/system/config/global/*.yml` as its package-owned macOS defaults catalog. Each definition contains `key`, optional `domain`, `type`, and `value`.
Local system definitions under `~/.config/mev/roles/system/global/*.yml` override or extend package definitions with the same `(domain, key)` identity. Duplicate identities within either layer are invalid.
`mev backup system` writes the effective current settings to the local system config tree while preserving definition file paths.

### Default Applications

Filename extensions are declared without a leading dot under each application's `extensions` list. Each application handles all LaunchServices roles for its declared extensions.
The bundled collection excludes extensions that resolve to dynamic or ambiguous LaunchServices types on macOS.
The bundled collection provides a conservative default set: `Zed` for source and config files and `Preview` for common document and image formats.
Browser defaults are not managed because macOS may require interactive user approval. The handler changes execute only when the `duti` role is selected explicitly.

```yaml
---
default_apps:
  - bundle_id: dev.zed.Zed
    extensions:
      - md
  - bundle_id: com.apple.Preview
    extensions:
      - pdf
```

## Release

`v*` tag push: `.github/workflows/release.yml` delegates to `.github/workflows/build.yml`, and the build job attaches `mev-darwin-aarch64` plus its SHA256 file directly to GitHub Releases
