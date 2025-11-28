import '../../ansible.just'

# Install menv convenience wrapper
menv:
  @echo "🚀 Installing menv command wrapper..."
  @just _run_ansible "menv" "common" "menv"
