#!/bin/bash
set -euo pipefail

# ================================================
# macOS システム設定を適用
# ================================================
#
# このスクリプトは、生成された設定ファイル `macos-settings.sh` を
# 実行して、macOS のシステム設定を適用します。
#
# ================================================

# スクリプトのベースディレクトリを決定
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SETTINGS_FILE="${BASE_DIR}/macos/config/system-defaults/macos-settings.sh"

echo "🚀 Applying macOS system settings..."

# 依存関係の確認とインストール: displayplacer
echo "[INFO] Checking and installing dependencies: displayplacer"
if ! command -v displayplacer &>/dev/null; then
    if ! command -v brew &>/dev/null; then
        echo "[WARN] Homebrew is not installed. Cannot install displayplacer."
        echo "[INFO] Please install Homebrew first: https://brew.sh/"
    else
        echo "[INFO] displayplacer not found. Installing via Homebrew..."
        brew install displayplacer
        echo "[SUCCESS] displayplacer installed."
    fi
else
    echo "[INFO] displayplacer is already installed."
fi

# 設定ファイルの存在確認と実行
if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo "[WARN] Settings file not found: ${SETTINGS_FILE}"
    echo "[INFO] You can generate it by running 'make backup-settings'."
else
    echo "[INFO] Sourcing settings file: ${SETTINGS_FILE}"
    # `source` を使用して設定を適用するが、エラーが発生しても続行
    if ! source "${SETTINGS_FILE}"; then
        echo "[WARN] Some errors occurred while applying macOS settings, but continuing."
    else
        echo "[SUCCESS] macOS system settings have been applied."
    fi
fi

echo ""
echo "==== Start: Verifying settings file... ===="
if [ ! -f "${SETTINGS_FILE}" ]; then
    echo "[ERROR] macOS settings file not found: ${SETTINGS_FILE}"
    echo "❌ Settings file verification failed."
    exit 1
else
    echo "[SUCCESS] macOS settings file exists."
    echo "✅ macOS settings application and verification completed."
fi
