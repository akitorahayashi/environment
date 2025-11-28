import '../../ansible.just'

# Setup common Homebrew formulae packages only
brew-formulae:
  @echo "  -> Running Homebrew formulae setup with config: ansible/roles/brew/config"
  @just _run_ansible "brew" "common" "brew-formulae"

# Install common cask packages only
brew-cask:
  @echo "🚀 Installing common Brew Casks..."
  @just _run_ansible "brew" "common" "brew-cask"

# Install MacBook-specific cask
mbk-brew-cask:
  @echo "🚀 Installing MacBook-specific Brew Casks..."
  @just _run_ansible "brew" "macbook" "brew-cask"

# Install Mac Mini-specific cask packages
mmn-brew-cask:
  @echo "🚀 Installing Mac Mini-specific Brew Casks..."
  @just _run_ansible "brew" "mac-mini" "brew-cask"
