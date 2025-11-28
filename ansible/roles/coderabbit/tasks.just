import '../../ansible.just'

# Setup CodeRabbit CLI
coderabbit:
  @echo "🚀 Running common CodeRabbit setup..."
  @just _run_ansible "coderabbit" "common" "coderabbit"
