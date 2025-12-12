import '../../ansible.just'

# Setup VS Code settings and extensions
vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "editor" "common" "vscode"

# Setup Cursor settings and CLI
cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "editor" "common" "cursor"

# Setup Xcode configuration only
xcode:
  @echo "🚀 Running common Xcode setup..."
  @just _run_ansible "editor" "common" "xcode"

# Backup current VSCode extensions
backup-vscode-extensions:
  @echo "🚀 Backing up current VSCode extensions..."
  @uv run python {{root_dir}}/ansible/scripts/editor/backup-extensions.py "{{root_dir}}/ansible/roles/editor/config/common"
  @echo "✅ VSCode extensions backup completed."
