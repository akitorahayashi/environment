import '../../ansible.just'

# Setup Python platform and tools
python:
    @echo "🚀 Running common Python setup..."
    @just python-platform
    @just python-tools
    @just aider

python-platform:
    @just _run_ansible "python" "common" "python-platform"

python-tools:
    @echo "🚀 Installing common Python tools from config: ansible/roles/python/config/common"
    @just _run_ansible "python" "common" "python-tools"

aider:
    @echo "🚀 Running common Aider setup..."
    @just _run_ansible "python" "common" "aider"

uv:
    @echo "🚀 Running common uv setup..."
    @just _run_ansible "python" "common" "uv"
