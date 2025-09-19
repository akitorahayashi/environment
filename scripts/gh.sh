#!/bin/bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <config-dir>" >&2
    exit 1
fi

CONFIG_DIR=$1
GH_CONFIG_DIR="${HOME}/.config/gh"
GH_CONFIG_FILE="${GH_CONFIG_DIR}/config.yml"
SOURCE_CONFIG_FILE="${CONFIG_DIR}/gh/config.yml"

# ================================================
# GitHub CLI (gh) installation and configuration
# ================================================
#
# 1. Install gh (via Homebrew)
# 2. Place gh configuration file (config.yml)
#
# ================================================

echo "🚀 Setting up GitHub CLI (gh)..."

# 1. gh のインストール
echo "[INFO] Checking and installing GitHub CLI (gh) if not present..."
if ! command -v gh &> /dev/null; then
    echo "[INFO] gh not found. Installing via Homebrew..."
    brew install gh
    echo "[SUCCESS] gh installed successfully."
else
    echo "[INFO] gh is already installed."
fi

# 2. gh の設定ファイル(config.yml)を配置
echo "[INFO] Setting up gh config..."

if [ ! -f "${SOURCE_CONFIG_FILE}" ]; then
    echo "[ERROR] Source config file not found at ${SOURCE_CONFIG_FILE}" >&2
    exit 1
fi

echo "[INFO] Creating gh config directory at ${GH_CONFIG_DIR}..."
mkdir -p "${GH_CONFIG_DIR}"

echo "[INFO] Creating symbolic link for config.yml at ${GH_CONFIG_FILE}..."
ln -sf "${SOURCE_CONFIG_FILE}" "${GH_CONFIG_FILE}"
echo "[SUCCESS] gh config file symlinked."


# Verification step
echo ""
echo "==== Start: Verifying gh setup... ===="
verification_failed=false

# gh command verification
if ! command -v gh &> /dev/null; then
    echo "[ERROR] gh command is not available."
    verification_failed=true
else
    echo "[SUCCESS] gh command is available: $(gh --version)"
fi

# Alias verification
# We check for a specific alias that should exist in the new config file.
if ! gh alias list | grep -q "re-ls"; then
    echo "[ERROR] gh alias 're-ls' was not set correctly. Check ${GH_CONFIG_FILE}."
    verification_failed=true
else
    echo "[SUCCESS] gh alias 're-ls' is set."
fi

if [ "${verification_failed}" = "true" ]; then
    echo "❌ gh setup verification failed."
    exit 1
else
    echo "✅ gh setup verified successfully."
fi
