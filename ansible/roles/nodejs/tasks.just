import '../../ansible.just'

# Setup Node.js platform and tools
nodejs:
  @echo "🚀 Running common Node.js setup..."
  @just nodejs-platform
  @just nodejs-tools
  @just llm

# Setup Node.js platform only
nodejs-platform:
  @echo "🚀 Running common Node.js platform setup..."
  @just _run_ansible "nodejs" "common" "nodejs-platform"

# Install Node.js tools only
nodejs-tools:
  @echo "🚀 Installing common Node.js tools from config: ansible/roles/nodejs/config/common"
  @just _run_ansible "nodejs" "common" "nodejs-tools"

# Setup Node.js based LLM tools (Claude, Gemini, Codex)
llm:
  @echo "🚀 Setting up Node.js LLM tools..."
  @just _run_ansible "nodejs" "common" "llm"
