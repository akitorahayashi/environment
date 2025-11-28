import '../../ansible.just'

# Configure GitHub CLI settings
gh:
  @echo "🚀 Running GitHub CLI setup..."
  @just _run_ansible "gh" "common" "gh"
