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

echo "==== Start: Python Global Tools Setup ===="

# Initialize pyenv for the current shell, in case it's not already.
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Make pipx available in the current shell
export PATH="$HOME/.local/bin:$PATH"

changed=false

# If the python version was changed by platform.sh, reinstall all pipx tools.
PYTHON_VERSION_CHANGE_FLAG="/tmp/python_version_changed"
if [ -f "$PYTHON_VERSION_CHANGE_FLAG" ]; then
    echo "[INFO] Python version has changed, reinstalling pipx tools..."
    if command -v pipx &> /dev/null && pipx list --short 2>/dev/null | grep -q .; then
        echo "[REINSTALL] Reinstalling pipx tools for the new Python version..."
        # We need to get the current python version to pass to reinstall-all
        PYTHON_VERSION_FILE="$REPO_ROOT/$CONFIG_DIR_PROPS/python/.python-version"
        PYTHON_VERSION="$(tr -d '[:space:]' < "$PYTHON_VERSION_FILE")"
        pipx reinstall-all --python "$(pyenv which python)"
        changed=true
    else
        echo "[INFO] No pipx tools to reinstall."
    fi
    # Clean up the flag file
    rm "$PYTHON_VERSION_CHANGE_FLAG"
fi

# Install tools managed by pipx
PIPX_TOOLS_FILE="$REPO_ROOT/$CONFIG_DIR_PROPS/python/pipx-tools.txt"
if [ ! -f "$PIPX_TOOLS_FILE" ]; then
    echo "[ERROR] pipx-tools.txt not found: $PIPX_TOOLS_FILE"
    exit 1
fi

echo "[INFO] Installing tools from $PIPX_TOOLS_FILE..."
installed_tools_output=$(pipx list)

while IFS= read -r tool_package_raw || [ -n "$tool_package_raw" ]; do
    # Remove comments and trim whitespace
    tool_package="${tool_package_raw%%#*}"
    tool_package="$(echo "$tool_package" | xargs)"
    # Skip empty lines
    if [[ -z "$tool_package" ]]; then
        continue
    fi

    # Check if the package is already installed
    if echo "$installed_tools_output" | grep -q "package $tool_package "; then
        echo "[INFO] $tool_package is already installed."
    else
        echo "[INSTALL] $tool_package"
        # We need the current python version for the installation
        if ! pipx install "$tool_package" --python "$(pyenv which python)"; then
            echo "[ERROR] Failed to install $tool_package" >&2
            exit 1
        fi
        changed=true
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi
done < "$PIPX_TOOLS_FILE"

echo "[SUCCESS] Python global tools setup complete."

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# --- Verification ---
echo "==== Start: Verifying Python Global Tools..."
verification_failed=false

# Verify pipx tools
if [ ! -f "$PIPX_TOOLS_FILE" ]; then
    echo "[ERROR] pipx-tools.txt not found: $PIPX_TOOLS_FILE"
    exit 1
fi

echo "[INFO] Verifying tools listed in $PIPX_TOOLS_FILE..."
installed_tools_output_verify=$(pipx list)

while IFS= read -r tool_package_raw || [ -n "$tool_package_raw" ]; do
    tool_package="${tool_package_raw%%#*}"
    tool_package="$(echo "$tool_package" | xargs)"
    if [[ -z "$tool_package" ]]; then
        continue
    fi

    if echo "$installed_tools_output_verify" | grep -q "package $tool_package "; then
        echo "[SUCCESS] $tool_package is installed correctly."
    else
        echo "[ERROR] $tool_package is not installed."
        verification_failed=true
    fi
done < "$PIPX_TOOLS_FILE"

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Python global tools verification failed."
    exit 1
else
    echo "[SUCCESS] Python global tools verification complete."
fi