# Brew Role

The `brew` role manages Homebrew packages (CLI formulae) and casks (GUI apps) using curated Brewfiles.

## Tags
- `brew-formulae`
- `brew-cask`

These tags map to the Just recipes `just brew-formulae` and `just brew-cask`, and are included in `just common`.

## Tasks
- `tasks/main.yml` conditionally includes `formulae.yml` and `cask.yml` when the matching tag is present.
- Each subtask runs `brew bundle --file=<Brewfile>` and reports changes when bundles install new items.

## Configuration
- Common manifests live under `ansible/roles/brew/config/common/formulae/Brewfile` and `.../cask/Brewfile`.
- Machine-specific overrides reside in `ansible/roles/brew/config/profiles/<profile>/` and are discovered via `first_found`. If the profile-specific file is missing, the role falls back to the common Brewfile.

Re-run `just brew-formulae` or `just brew-cask` after editing Brewfiles to sync installations.
