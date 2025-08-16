#!/bin/bash
set -euo pipefail


# スクリプトの引数から設定ディレクトリのパスを取得
# 引数が提供されない場合は、デフォルトの共通設定ディレクトリを使用
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    CONFIG_DIR_PROPS="config/common"
fi

# ================================================
# macOS システム設定を適用
# ================================================
#
# このスクリプトは、生成された設定ファイル `system-defaults.sh` を
# 実行して、macOS のシステム設定を適用します。
#
# ================================================

SETTINGS_FILE="$REPO_ROOT/$CONFIG_DIR_PROPS/system-defaults/system-defaults.sh"

echo "🚀 Applying macOS system defaults..."

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
    echo "[WARN] System defaults file not found: ${SETTINGS_FILE}"
    echo "[INFO] You can generate it by running 'make backup-defaults'."
else
    echo "[INFO] Sourcing system defaults file: ${SETTINGS_FILE}"
    # shellcheck source=/dev/null
    if ! source "${SETTINGS_FILE}"; then
        echo "[ERROR] Failed to apply macOS system defaults from ${SETTINGS_FILE}"
        exit 1
    else
        echo "[SUCCESS] macOS system defaults have been applied."
    fi
fi

echo ""
echo "==== Start: Verifying system defaults file... ===="
if [ ! -f "${SETTINGS_FILE}" ]; then
    echo "[ERROR] macOS system defaults file not found: ${SETTINGS_FILE}"
    echo "❌ System defaults file verification failed."
    exit 1
else
    echo "[SUCCESS] macOS system defaults file exists."
    echo "✅ macOS system defaults application and verification completed."
fi
