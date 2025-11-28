import '../../ansible.just'

# Apply macOS system defaults
apply-system:
  @echo "🚀 Applying common system defaults..."
  @just _run_ansible "system" "common" "system"

# Backup current macOS system defaults
backup-system:
  @echo "🚀 Backing up current macOS system defaults..."
  @{{root_dir}}/ansible/scripts/system/backup-system.py "{{root_dir}}/ansible/roles/system/config/common"
  @echo "✅ macOS system defaults backup completed."
