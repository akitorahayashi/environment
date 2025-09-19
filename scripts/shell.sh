#!/bin/bash
set -euo pipefail

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# ================================================
# Create symbolic links for shell configuration files
# ================================================
#
# This script creates symbolic links for .zprofile and .zshrc from the repository
# to the home directory,
# and also links the split configuration files in the ~/.zsh directory.
#
# ================================================

# Target files and link destinations
ZPROFILE_SOURCE="$CONFIG_DIR_PROPS/shell/.zprofile"
ZPROFILE_DEST="${HOME}/.zprofile"

ZSHRC_SOURCE="$CONFIG_DIR_PROPS/shell/.zshrc"
ZSHRC_DEST="${HOME}/.zshrc"

ZSH_CONFIG_SOURCE="$CONFIG_DIR_PROPS/shell/.zsh"
ZSH_CONFIG_DEST="${HOME}/.zsh"

# Remove and recreate the ~/.zsh directory
echo "🧹 Cleaning ~/.zsh directory..."
rm -rf "${ZSH_CONFIG_DEST}"
mkdir -p "${ZSH_CONFIG_DEST}"

# Create symbolic link for .zprofile
echo "🚀 Creating symbolic link for .zprofile..."
ln -sf "${ZPROFILE_SOURCE}" "${ZPROFILE_DEST}"
echo "[SUCCESS] Created symbolic link for .zprofile: ${ZPROFILE_DEST} -> ${ZPROFILE_SOURCE}"

# Create symbolic link for .zshrc
echo "🚀 Creating symbolic link for .zshrc..."
ln -sf "${ZSHRC_SOURCE}" "${ZSHRC_DEST}"
echo "[SUCCESS] Created symbolic link for .zshrc: ${ZSHRC_DEST} -> ${ZSHRC_SOURCE}"

# Create symbolic links for files in the .zsh directory
echo "🚀 Creating symbolic links for .zsh configuration files..."
for config_file in "${ZSH_CONFIG_SOURCE}"/*.zsh; do
    if [ -f "$config_file" ]; then
        filename=$(basename "$config_file")
        ln -sf "$config_file" "${ZSH_CONFIG_DEST}/$filename"
        echo "[SUCCESS] Created symbolic link: ${ZSH_CONFIG_DEST}/$filename -> $config_file"
    fi
done

echo ""
echo "==== Start: Verifying shell configuration links... ===="
verification_failed=false

# .zprofile の検証
if [ ! -L "${ZPROFILE_DEST}" ] || [ ! "${ZPROFILE_DEST}" -ef "${ZPROFILE_SOURCE}" ]; then
    echo "[ERROR] .zprofile symbolic link is incorrect."
    echo "  Expected: ${ZPROFILE_DEST} -> ${ZPROFILE_SOURCE}"
    echo "  Actual: $(readlink "${ZPROFILE_DEST}" 2>/dev/null || echo 'N/A')"
    verification_failed=true
else
    echo "[SUCCESS] .zprofile symbolic link is correct."
fi

# .zshrc の検証
if [ ! -L "${ZSHRC_DEST}" ] || [ ! "${ZSHRC_DEST}" -ef "${ZSHRC_SOURCE}" ]; then
    echo "[ERROR] .zshrc symbolic link is incorrect."
    echo "  Expected: ${ZSHRC_DEST} -> ${ZSHRC_SOURCE}"
    echo "  Actual: $(readlink "${ZSHRC_DEST}" 2>/dev/null || echo 'N/A')"
    verification_failed=true
else
    echo "[SUCCESS] .zshrc symbolic link is correct."
fi

# .zsh ディレクトリ内のファイルの検証
for config_file in "${ZSH_CONFIG_SOURCE}"/*.zsh; do
    if [ -f "$config_file" ]; then
        filename=$(basename "$config_file")
        dest_file="${ZSH_CONFIG_DEST}/$filename"
        if [ ! -L "$dest_file" ] || [ ! "$dest_file" -ef "$config_file" ]; then
            echo "[ERROR] $filename symbolic link is incorrect."
            echo "  Expected: $dest_file -> $config_file"
            echo "  Actual: $(readlink "$dest_file" 2>/dev/null || echo 'N/A')"
            verification_failed=true
        else
            echo "[SUCCESS] $filename symbolic link is correct."
        fi
    fi
done

if [ "${verification_failed}" = "true" ]; then
    echo "❌ Shell link verification failed."
    exit 1
else
    echo "✅ Shell configuration links created and verified successfully."
fi
