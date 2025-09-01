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

# Load nvm environment to ensure npm is available from the correct version
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$(brew --prefix nvm)/nvm.sh"
    # Sourcing nvm.sh is enough to activate the default version.
else
    echo "[ERROR] nvm.sh not found. Please run the platform setup first."
    exit 1
fi

# Check if the node version was changed and inform the user.
NODE_VERSION_CHANGE_FLAG="/tmp/node_version_changed"
if [ -f "$NODE_VERSION_CHANGE_FLAG" ]; then
    echo "[INFO] Node.js version has changed. Global packages will be installed for the new version."
    echo "[INFO] nvm manages packages on a per-version basis, so packages for older versions are not removed."
    rm "$NODE_VERSION_CHANGE_FLAG"
fi

# Install global packages
packages_file="$REPO_ROOT/$CONFIG_DIR_PROPS/node/global-packages.json"
if [ ! -f "$packages_file" ]; then
    echo "[ERROR] global-packages.json not found: $packages_file"
    exit 1
fi

echo "[INFO] Installing/updating global packages from $packages_file..."
if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] 'jq' is required but not found. Run 'make node-platform' first or install jq." >&2
  exit 1
fi

packages_json=$(jq -r '.globalPackages | keys[]' "$packages_file")
if [ -z "$packages_json" ]; then
    echo "[WARN] No packages defined in global-packages.json"
else
    while IFS= read -r pkg_name; do
        # Check if package is installed
        if npm list -g "$pkg_name" &>/dev/null; then
            echo "[INFO] $pkg_name is already installed, checking for updates..."
        else
            echo "[INSTALL] $pkg_name@latest"
            echo "IDEMPOTENCY_VIOLATION" >&2
        fi
        
        # Install/update the package (npm handles existing packages gracefully)
        npm install -g "$pkg_name@latest"
    done <<< "$packages_json"
fi

echo "[SUCCESS] Node.js global packages setup complete."

# --- Verification ---
echo "==== Start: Verifying Node.js Global Packages..."
verification_failed=false

if [ ! -f "$packages_file" ]; then
    echo "[ERROR] global-packages.json not found for verification: $packages_file"
    exit 1
fi

packages_to_verify=$(jq -r '.globalPackages | keys[]' "$packages_file")
if [ -n "$packages_to_verify" ]; then
    echo "[INFO] Verifying packages listed in $packages_file..."
    missing_packages=0
    while IFS= read -r package; do
        # Use `npm list -g` which returns a non-zero exit code if package is not found.
        if ! npm list -g "$package" &>/dev/null; then
            echo "[ERROR] Global package '$package' is not installed."
            ((missing_packages++))
        else
            echo "[SUCCESS] Global package '$package' is installed."
        fi
    done <<< "$packages_to_verify"
    if [ "$missing_packages" -gt 0 ]; then
        verification_failed=true
    fi
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Node.js global packages verification failed."
    exit 1
else
    echo "[SUCCESS] Node.js global packages verification complete."
fi
