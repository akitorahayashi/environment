#!/bin/bash

# This script is meant to be called from the Makefile, which passes the config dir.
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

echo "==== Start: Node.js Platform Setup ===="

# Install dependencies: nvm, jq
echo "[INFO] Checking and installing dependencies: nvm, jq"
dependencies_changed=false
if ! brew list nvm &> /dev/null; then
    brew install nvm
    dependencies_changed=true
fi
if ! command -v jq &> /dev/null; then
    brew install jq
    dependencies_changed=true
fi
if [ "$dependencies_changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# Load nvm environment
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$(brew --prefix nvm)/nvm.sh"
else
    echo "[ERROR] nvm.sh not found. Please check your nvm installation."
    exit 1
fi

# Read Node.js version from .nvmrc file
NODE_VERSION_FILE="$REPO_ROOT/$CONFIG_DIR_PROPS/node/.nvmrc"
if [ ! -f "$NODE_VERSION_FILE" ]; then
    echo "[ERROR] .nvmrc file not found: $NODE_VERSION_FILE"
    exit 1
fi
NODE_VERSION=""
if ! read -r NODE_VERSION < "$NODE_VERSION_FILE"; then
    echo "[ERROR] Failed to read version from .nvmrc file."
    exit 1
fi
NODE_VERSION="${NODE_VERSION//[[:space:]]/}"
readonly NODE_VERSION
if [ -z "$NODE_VERSION" ]; then
    echo "[ERROR] Failed to read version from .nvmrc file."
    exit 1
fi
echo "[INFO] Node.js version specified in .nvmrc is ${NODE_VERSION}"

# Install and configure Node.js via nvm
node_changed=false
echo "[INFO] Installing the specified Node.js version..."

# `nvm install` is idempotent; it installs only if the version is missing.
if nvm install "$NODE_VERSION"; then
    echo "[SUCCESS] Node.js ${NODE_VERSION} installation/check complete."
else
    echo "[ERROR] Failed to install Node.js ${NODE_VERSION}."
    exit 1
fi

# Check if the default alias points to the specified version
expected_default_target="$(nvm version "$NODE_VERSION")"
current_default_target="$(nvm alias default 2>/dev/null | awk -F'->' 'NR==1{gsub(/^[ \t]+|[ \t]+$/,"",$2); print $2}' | awk '{print $1}')"
if [[ "$current_default_target" != "$expected_default_target" ]]; then
    echo "[CONFIGURING] Setting Node.js ${expected_default_target} as the default version."
    if nvm alias default "$expected_default_target"; then
        echo "[SUCCESS] Set default version to ${expected_default_target}."
        node_changed=true
    else
        echo "[ERROR] Failed to set the default version."
        exit 1
    fi
else
    echo "[CONFIGURED] Node.js ${expected_default_target} is already the default version."
fi

# Create a flag file if the version changed.
NODE_VERSION_CHANGE_FLAG="/tmp/node_version_changed"
if [ -f "$NODE_VERSION_CHANGE_FLAG" ]; then
    rm "$NODE_VERSION_CHANGE_FLAG"
fi
if [ "$node_changed" = true ]; then
    touch "$NODE_VERSION_CHANGE_FLAG"
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# Use the specified version in the current shell
if ! nvm use "$NODE_VERSION" > /dev/null; then
    echo "[ERROR] Failed to switch to Node.js ${NODE_VERSION}."
    exit 1
fi

echo "[SUCCESS] Node.js platform setup complete."

# --- Verification ---
echo "==== Start: Verifying Node.js Platform..."
verification_failed=false

# Re-read the expected version from .nvmrc for verification
NODE_VERSION_FILE_VERIFY="$REPO_ROOT/$CONFIG_DIR_PROPS/node/.nvmrc"
if [ ! -f "$NODE_VERSION_FILE_VERIFY" ]; then
    echo "[ERROR] .nvmrc file not found for verification: $NODE_VERSION_FILE_VERIFY"
    exit 1
fi
EXPECTED_NODE_VERSION_VERIFY=""
if ! read -r EXPECTED_NODE_VERSION_VERIFY < "$NODE_VERSION_FILE_VERIFY"; then
    echo "[ERROR] Failed to read version from .nvmrc file for verification."
    exit 1
fi
EXPECTED_NODE_VERSION_VERIFY="${EXPECTED_NODE_VERSION_VERIFY//[[:space:]]/}"

# Check if the current nvm version matches the expected one
EXPECTED_VERSION_STRING=$(nvm version "$EXPECTED_NODE_VERSION_VERIFY")
CURRENT_VERSION_STRING=$(nvm current)

if [ "$CURRENT_VERSION_STRING" != "$EXPECTED_VERSION_STRING" ]; then
    echo "[ERROR] Node.js version mismatch. Expected: ${EXPECTED_NODE_VERSION_VERIFY} (${EXPECTED_VERSION_STRING}), Current: ${CURRENT_VERSION_STRING}"
    verification_failed=true
else
    echo "[SUCCESS] Node.js version is correct: $(node --version)"
    echo "[SUCCESS] npm is available: $(npm --version)"
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Node.js platform verification failed."
    exit 1
else
    echo "[SUCCESS] Node.js platform verification complete."
fi
