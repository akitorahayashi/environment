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

echo "==== Start: Python Platform Setup ===="

changed=false
# Install pyenv dependency
echo "[INFO] Checking and installing dependency: pyenv"
if ! command -v pyenv &> /dev/null; then
    brew install pyenv
    changed=true
fi

# Initialize pyenv for the current shell
if command -v pyenv 1>/dev/null 2>&1; then
    eval "$(pyenv init --path)"
    eval "$(pyenv init -)"
fi

# Read the Python version from the .python-version file
PYTHON_VERSION_FILE="$REPO_ROOT/$CONFIG_DIR_PROPS/python/.python-version"
if [ ! -f "$PYTHON_VERSION_FILE" ]; then
    echo "[ERROR] .python-version file not found: $PYTHON_VERSION_FILE"
    exit 1
fi
PYTHON_VERSION="$(tr -d '[:space:]' < "$PYTHON_VERSION_FILE")"
readonly PYTHON_VERSION
if [ -z "$PYTHON_VERSION" ]; then
    echo "[ERROR] Failed to read version from .python-version file."
    exit 1
fi
echo "[INFO] Python version specified in .python-version is ${PYTHON_VERSION}"

# Install the specified Python version if it's not already installed
if ! pyenv versions --bare | grep -q "^${PYTHON_VERSION}$"; then
    echo "[INSTALL] Python ${PYTHON_VERSION}"
    if ! pyenv install --skip-existing "${PYTHON_VERSION}"; then
        echo "[ERROR] Failed to install Python ${PYTHON_VERSION}"
        exit 1
    fi
    changed=true
else
    echo "[INFO] Python ${PYTHON_VERSION} is already installed"
fi

# Set the global pyenv version to the one specified in .python-version
# and create a flag file if the version changes.
PYTHON_VERSION_CHANGE_FLAG="/tmp/python_version_changed"
if [ -f "$PYTHON_VERSION_CHANGE_FLAG" ]; then
    rm "$PYTHON_VERSION_CHANGE_FLAG"
fi

if [ "$(pyenv global)" != "${PYTHON_VERSION}" ]; then
    echo "[CONFIG] Setting pyenv global to ${PYTHON_VERSION}"
    pyenv global "${PYTHON_VERSION}"
    pyenv rehash
    changed=true
    # Signal that the version has changed for the tools script
    touch "$PYTHON_VERSION_CHANGE_FLAG"
else
    echo "[INFO] pyenv global is already set to ${PYTHON_VERSION}"
fi

# Install pipx
if ! command -v pipx &> /dev/null; then
    echo "[INSTALL] pipx"
    "$(pyenv which python)" -m pip install --user pipx
    # The `ensurepath` command is effective from the next shell session.
    # To make it effective immediately, we add the path manually.
    export PATH="$HOME/.local/bin:$PATH"
    hash -r # Clear command cache
    pipx ensurepath
    changed=true
else
    echo "[INFO] pipx is already installed"
fi

echo "[SUCCESS] Python platform setup complete."

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# --- Verification ---
echo "==== Start: Verifying Python Platform..."
verification_failed=false

# Verify pyenv
if ! command -v pyenv >/dev/null 2>&1; then
    echo "[ERROR] pyenv command not found."
    verification_failed=true
else
    echo "[SUCCESS] pyenv: $(pyenv --version)"
fi

# Verify Python version
if [ "$(pyenv version-name)" != "${PYTHON_VERSION}" ]; then
    echo "[ERROR] Python version is not set to ${PYTHON_VERSION}. Current: $(pyenv version-name)"
    verification_failed=true
else
    echo "[SUCCESS] Python: $(python -V)"
fi

# Verify pipx
if ! command -v pipx >/dev/null 2>&1; then
    echo "[ERROR] pipx command not found."
    verification_failed=true
else
    echo "[SUCCESS] pipx: $(pipx --version)"
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Python platform verification failed."
    exit 1
else
    echo "[SUCCESS] Python platform verification complete."
fi
