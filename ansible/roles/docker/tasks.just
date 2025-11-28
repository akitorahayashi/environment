import '../../ansible.just'

# Pull Docker images
docker-images:
  @echo "🚀 Checking/verifying Docker images..."
  @just _run_ansible "docker" "common" "docker"
