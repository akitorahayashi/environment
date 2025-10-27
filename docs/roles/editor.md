# Editor Role

The `editor` role synchronizes Visual Studio Code and Cursor so both editors share settings, keybindings, and extensions.

## Tags
- `vscode`
- `cursor`

Trigger with `just vscode` or `just cursor`; both run during `just common`.

## VS Code Tasks (`tasks/vscode.yml`)
- Install VS Code via Homebrew Cask.
- Ensure `~/Library/Application Support/Code/User` exists.
- Symlink `settings.json` and `keybindings.json` from `ansible/roles/editor/config/common/`.
- Load `vscode-extensions.json`, parse the `extensions` array, and install each extension with `code --install-extension --force` (errors ignored so the run remains idempotent).

## Cursor Tasks (`tasks/cursor.yml`)
- Install Cursor via Homebrew Cask and download the Cursor CLI installer (checksum pinned) into `~/.ansible/tmp`.
- Install the CLI (`cursor-agent`) and remove the installer.
- Symlink shared settings and keybindings into `~/Library/Application Support/Cursor/User`.
- Parse `cursor-extensions.json` and install each extension with `cursor --install-extension`.

## Backup Utilities
`ansible/scripts/editor/backup-extensions.py` exports the current VS Code extension list to `vscode-extensions.json`. Run `just backup-vscode-extensions` (or `make vscode-extensions-backup`) after updating extensions manually.

Keeping editor configuration under version control ensures every machine starts with the same UX.
