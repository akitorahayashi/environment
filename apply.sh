#!/bin/bash

set -euo pipefail

# Move to the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# --- Shell Setup ---
echo "[Start] Setting up shell configuration files..."

# Create symbolic links
echo "[INFO] Creating symbolic links for shell configuration files..."
ln -sf "$SCRIPT_DIR/macos/config/shell/.zprofile" "$HOME/.zprofile"
echo "[SUCCESS] Created symbolic link for .zprofile."
ln -sf "$SCRIPT_DIR/macos/config/shell/.zshrc" "$HOME/.zshrc"
echo "[SUCCESS] Created symbolic link for .zshrc."

echo "[SUCCESS] Shell environment setup is complete."

# --- macOS Settings Setup ---
echo "[Start] Applying Mac system settings..."

# Install dependencies
echo "[INFO] Checking and installing dependencies: displayplacer"
if ! command -v displayplacer &>/dev/null; then
  brew install displayplacer
fi

# Apply settings
settings_file="$SCRIPT_DIR/macos/config/macos/macos-settings.sh"
if [[ ! -f "$settings_file" ]]; then
  echo "[WARN] $settings_file not found."
else
  if ! source "$settings_file" 2>/dev/null; then
    echo "[WARN] Some errors occurred while applying Mac settings, but continuing."
  else
    echo "[SUCCESS] Mac system settings have been applied."
  fi
fi

# --- Verification ---
echo "==== Start: Verifying setup... ===="
verification_failed=false

# Verify .zprofile
if [ ! -L "$HOME/.zprofile" ] || [ "$(readlink "$HOME/.zprofile")" != "$SCRIPT_DIR/macos/config/shell/.zprofile" ]; then
  echo "[ERROR] .zprofile symbolic link is incorrect."
  verification_failed=true
else
  echo "[SUCCESS] .zprofile symbolic link is correct."
fi

# Verify .zshrc
if [ ! -L "$HOME/.zshrc" ] || [ "$(readlink "$HOME/.zshrc")" != "$SCRIPT_DIR/macos/config/shell/.zshrc" ]; then
  echo "[ERROR] .zshrc symbolic link is incorrect."
  verification_failed=true
else
  echo "[SUCCESS] .zshrc symbolic link is correct."
fi

# Verify macOS settings file
if [ ! -f "$settings_file" ]; then
  echo "[ERROR] macOS settings file not found: $settings_file"
  verification_failed=true
else
  echo "[SUCCESS] macOS settings file exists."
fi

if [ "$verification_failed" = "true" ]; then
  echo "[ERROR] Verification failed."
  exit 1
else
  echo "[OK] All setups have been verified successfully!"
fi

exit 0
