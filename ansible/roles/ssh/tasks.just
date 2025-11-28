import '../../ansible.just'

# Setup SSH configuration
ssh:
  @echo "🚀 Running common SSH setup..."
  @just _run_ansible "ssh" "common" "ssh"
