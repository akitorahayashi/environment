import '../../ansible.just'

# Setup VS Code settings and extensions
vscode:
  @echo "🚀 Running common VS Code setup..."
  @just _run_ansible "editor" "common" "vscode"

# Setup Cursor settings and CLI
cursor:
  @echo "🚀 Running common Cursor setup..."
  @just _run_ansible "editor" "common" "cursor"

# Backup current VSCode extensions
backup-vscode-extensions:
  @echo "🚀 Backing up current VSCode extensions..."
  @{{root_dir}}/ansible/scripts/editor/backup-extensions.py "{{root_dir}}/ansible/roles/editor/config/common"
  @echo "✅ VSCode extensions backup completed."
