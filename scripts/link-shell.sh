#!/bin/bash
set -euo pipefail

# REPO_ROOT is injected by the Makefile.

# スクリプトの引数から設定ディレクトリのパスを取得
# 引数が提供されない場合は、デフォルトの共通設定ディレクトリを使用
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    CONFIG_DIR_PROPS="config/common"
fi

# ================================================
# シェル設定ファイルのシンボリックリンクを作成
# ================================================
#
# このスクリプトは、リポジトリ内の .zprofile と .zshrc を
# ホームディレクトリにシンボリックリンクします。
#
# ================================================

# ターゲットファイルとリンク先
ZPROFILE_SOURCE="$REPO_ROOT/$CONFIG_DIR_PROPS/shell/.zprofile"
ZPROFILE_DEST="${HOME}/.zprofile"

ZSHRC_SOURCE="$REPO_ROOT/$CONFIG_DIR_PROPS/shell/.zshrc"
ZSHRC_DEST="${HOME}/.zshrc"

# .zprofile のシンボリックリンクを作成
echo "🚀 Creating symbolic link for .zprofile..."
ln -sf "${ZPROFILE_SOURCE}" "${ZPROFILE_DEST}"
echo "[SUCCESS] Created symbolic link for .zprofile: ${ZPROFILE_DEST} -> ${ZPROFILE_SOURCE}"

# .zshrc のシンボリックリンクを作成
echo "🚀 Creating symbolic link for .zshrc..."
ln -sf "${ZSHRC_SOURCE}" "${ZSHRC_DEST}"
echo "[SUCCESS] Created symbolic link for .zshrc: ${ZSHRC_DEST} -> ${ZSHRC_SOURCE}"

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

if [ "${verification_failed}" = "true" ]; then
    echo "❌ Shell link verification failed."
    exit 1
else
    echo "✅ Shell configuration links created and verified successfully."
fi
