#!/bin/bash

# This script is meant to be called from the Makefile, which passes the config dir and package name.
CONFIG_DIR_PROPS="$1"
PACKAGE_NAME="$2"

if [ -z "$CONFIG_DIR_PROPS" ] || [ -z "$PACKAGE_NAME" ]; then
    echo "[ERROR] This script requires a configuration directory path and a package name as arguments." >&2
    exit 1
fi

if [ -z "${REPO_ROOT:-}" ]; then
    echo "[ERROR] REPO_ROOT environment variable is not set. This script should be run via 'make'." >&2
    exit 1
fi

echo "==== Start: Node.js Global Package Setup for $PACKAGE_NAME ===="

# Load nvm environment
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$(brew --prefix nvm)/nvm.sh"
else
    echo "[ERROR] nvm.sh not found. Please run the platform setup first."
    exit 1
fi

packages_file="$REPO_ROOT/$CONFIG_DIR_PROPS/node/global-packages.json"
if [ ! -f "$packages_file" ]; then
    echo "[ERROR] global-packages.json not found: $packages_file"
    exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "[ERROR] 'jq' is required but not found. Run 'make node-platform' first or install jq." >&2
  exit 1
fi

pkg_full=$(jq -r --arg pkg "$PACKAGE_NAME" '.globalPackages | to_entries[] | select(.key == $pkg) | "\(.key)@\(.value)"' "$packages_file")

if [ -z "$pkg_full" ]; then
    echo "[ERROR] Package '$PACKAGE_NAME' not found in $packages_file"
    exit 1
fi

changed=false
pkg_name_only="${pkg_full%@*}"
installed_version=$(npm list -g --depth=0 "$pkg_name_only" 2>/dev/null | grep -E "$pkg_name_only@[0-9]" | awk -F'@' '{print $NF}' || true)
required_version=$(echo "$pkg_full" | awk -F'@' '{print $NF}')

if [ "$required_version" == "latest" ]; then
    if [ -z "$installed_version" ]; then
        echo "[INSTALL] $pkg_full"
        if npm install -g "$pkg_full"; then
            changed=true
        else
            echo "[ERROR] Failed to install $pkg_name_only"
            exit 1
        fi
    else
        echo "[INFO] $pkg_name_only is already installed (latest)."
    fi
elif [ "$installed_version" != "$required_version" ]; then
    echo "[INSTALL] $pkg_full (updating from $installed_version)"
    if npm install -g "$pkg_full"; then
        changed=true
    else
        echo "[ERROR] Failed to update $pkg_name_only"
        exit 1
    fi
else
    echo "[INFO] $pkg_name_only@$required_version is already installed."
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "[SUCCESS] Node.js global package setup for $PACKAGE_NAME complete."

# --- Verification ---
echo "==== Start: Verifying Node.js Global Package: $PACKAGE_NAME..."
if ! npm list -g "$PACKAGE_NAME" &>/dev/null; then
    echo "[ERROR] Global package '$PACKAGE_NAME' is not installed."
    exit 1
else
    echo "[SUCCESS] Global package '$PACKAGE_NAME' is installed."
fi
