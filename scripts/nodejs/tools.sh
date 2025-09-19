#!/bin/bash

# This script is meant to be called from the Makefile, which passes the config dir.
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

if [ -z "${REPO_ROOT:-}" ]; then
    echo "[ERROR] REPO_ROOT environment variable is not set. This script should be run via 'make'." >&2
    exit 1
fi

echo "==== Start: Node.js Global Packages Setup ===="

# Load nvm environment and ensure pnpm is available
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$(brew --prefix nvm)/nvm.sh"
    # Sourcing nvm.sh is enough to activate the default version.
else
    echo "[ERROR] nvm.sh not found. Please run the platform setup first."
    exit 1
fi

# Ensure pnpm is in PATH
export PNPM_HOME="$HOME/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Verify pnpm is available
if ! command -v pnpm &> /dev/null; then
    echo "[ERROR] pnpm not found. Please run 'make nodejs-platform' first."
    exit 1
fi

# Check if the node version was changed and inform the user.
NODE_VERSION_CHANGE_FLAG="/tmp/node_version_changed"
if [ -f "$NODE_VERSION_CHANGE_FLAG" ]; then
    echo "[INFO] Node.js version has changed. Global packages will be installed for the new version."
    echo "[INFO] nvm manages packages on a per-version basis, so packages for older versions are not removed."
    rm "$NODE_VERSION_CHANGE_FLAG"
fi

# Install global packages from config
packages_file="$REPO_ROOT/$CONFIG_DIR_PROPS/nodejs/global-packages.json"
if [ ! -f "$packages_file" ]; then
    echo "[ERROR] global-packages.json not found: $packages_file"
    exit 1
fi

echo "[INFO] Installing global Node.js packages from $packages_file..."

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] 'jq' is required but not found. Run 'make nodejs-platform' first or install jq." >&2
  exit 1
fi

packages_json=$(jq -r '.dependencies | keys[]' "$packages_file")
if [ -z "$packages_json" ]; then
    echo "[WARN] No packages defined in global-packages.json"
else
    while IFS= read -r pkg_name; do
        if pnpm list -g "$pkg_name" &>/dev/null; then
            echo "[INFO] $pkg_name is already installed, checking for updates..."
            pnpm install -g "$pkg_name@latest"
        else
            echo "[INSTALL] $pkg_name@latest"
            pnpm install -g "$pkg_name@latest"
            echo "IDEMPOTENCY_VIOLATION" >&2
        fi
    done <<< "$packages_json"
fi


echo "[SUCCESS] Node.js global packages setup complete."

# --- Verification ---
echo "==== Start: Verifying Node.js Global Packages..."

packages_to_verify=$(jq -r '.dependencies | keys[]' "$packages_file")
if [ -n "$packages_to_verify" ]; then
    echo "[INFO] Verifying packages listed in $packages_file..."
    missing_packages=0
    while IFS= read -r package; do
        if ! pnpm list -g "$package" &>/dev/null; then
            echo "[ERROR] Global package '$package' is not installed."
            ((missing_packages++))
        else
            echo "[SUCCESS] Global package '$package' is installed."
        fi
    done <<< "$packages_to_verify"
    
    if [ "$missing_packages" -gt 0 ]; then
        echo "[ERROR] Node.js global packages verification failed."
        exit 1
    fi
fi

echo "[SUCCESS] Node.js global packages verification complete."

# --- Create symlink for md-to-pdf config ---
echo "==== Creating symlink for md-to-pdf config ===="

config_source="$REPO_ROOT/$CONFIG_DIR_PROPS/nodejs/md-to-pdf-config.js"
symlink_target="$HOME/.md-to-pdf-config.js"

if [ -f "$config_source" ]; then
    if [ -L "$symlink_target" ] || [ -f "$symlink_target" ]; then
        echo "[INFO] Removing existing symlink/file at $symlink_target"
        rm "$symlink_target"
    fi
    echo "[INFO] Creating symlink: $symlink_target -> $config_source"
    ln -s "$config_source" "$symlink_target"
    echo "[SUCCESS] Symlink created successfully."
else
    echo "[WARN] md-to-pdf-config.js not found at $config_source, skipping symlink creation."
fi
