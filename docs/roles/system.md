# System Role

The `system` role encodes macOS defaults so machines converge on the same UI and hardware behavior.

## Tag
- `system`

Executed via `just apply-system` and automatically within `just common`.

## Tasks
- Install `displayplacer`, required for display presets, using Homebrew.
- Load `ansible/roles/system/config/common/system.yml` and apply each entry through the `community.general.osx_defaults` module.

## Configuration
- `system.yml` is generated from structured definition files under `config/common/definitions/` (grouped by feature such as `dock.yml`, `keyboard.yml`, etc.).
- Use `just backup-system` or `make system-backup` to regenerate `system.yml` by running `ansible/scripts/system/backup-system.py`. The script reads the definition files to determine which defaults to capture and normalizes values for YAML.

Log out or restart after applying this role to ensure all defaults take effect.
