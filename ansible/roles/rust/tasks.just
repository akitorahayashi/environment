import '../../ansible.just'

# Setup Rust environment with rustup and tools
rust:
  @echo "🚀 Running common Rust setup..."
  @just rust-platform
  @just rust-tools

# Setup Rust platform only
rust-platform:
  @echo "🚀 Running common Rust platform setup..."
  @just _run_ansible "rust" "common" "rust-platform"

# Install Rust tools only
rust-tools:
  @echo "🚀 Installing common Rust tools from config: ansible/roles/rust/config/common"
  @just _run_ansible "rust" "common" "rust-tools"

# Bootstrap ssv via HTTPS (Force install to ensure it exists for SSH setup)
ssv:
  @echo "🚀 Installing ssv via HTTPS for bootstrap..."
  @$HOME/.cargo/bin/cargo install ssv --git https://github.com/akitorahayashi/ssv.git --tag v0.1.0 --force
