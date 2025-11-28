import '../../ansible.just'

# Link common shell configuration files
shell:
  @echo "🚀 Linking common shell configuration..."
  @just _run_ansible "shell" "common" "shell"
