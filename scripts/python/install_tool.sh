#!/bin/bash

# This script is meant to be called from the Makefile, which passes the config dir and tool name.
CONFIG_DIR_PROPS="$1"
TOOL_PACKAGE="$2"

if [ -z "$CONFIG_DIR_PROPS" ] || [ -z "$TOOL_PACKAGE" ]; then
    echo "[ERROR] This script requires a configuration directory path and a tool name as arguments." >&2
    exit 1
fi

if [ -z "${REPO_ROOT:-}" ]; then
    echo "[ERROR] REPO_ROOT environment variable is not set. This script should be run via 'make'." >&2
    exit 1
fi

echo "==== Start: Python Global Tool Setup for $TOOL_PACKAGE ===="

# Initialize pyenv for the current shell
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Make pipx available
export PATH="$HOME/.local/bin:$PATH"

changed=false

# Check if the package is already installed
if pipx list | grep -q "package $TOOL_PACKAGE "; then
    echo "[INFO] $TOOL_PACKAGE is already installed."
else
    echo "[INSTALL] $TOOL_PACKAGE"
    if ! pipx install "$TOOL_PACKAGE" --python "$(pyenv which python)"; then
        echo "[ERROR] Failed to install $TOOL_PACKAGE" >&2
        exit 1
    fi
    changed=true
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "[SUCCESS] Python tool setup for $TOOL_PACKAGE complete."

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# --- Verification ---
echo "==== Start: Verifying Python Global Tool: $TOOL_PACKAGE..."
if pipx list | grep -q "package $TOOL_PACKAGE "; then
    echo "[SUCCESS] $TOOL_PACKAGE is installed correctly."
else
    echo "[ERROR] $TOOL_PACKAGE is not installed."
    exit 1
fi
