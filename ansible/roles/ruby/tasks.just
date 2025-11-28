import '../../ansible.just'

# Setup Ruby environment with rbenv
ruby:
  @echo "🚀 Running common Ruby setup..."
  @just _run_ansible "ruby" "common" "ruby"
