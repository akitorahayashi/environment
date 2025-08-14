#!/bin/bash
set -euo pipefail

# ================================================
# シェル設定ファイルのシンボリックリンクを作成
# ================================================
#
# このスクリプトは、リポジトリ内の .zprofile と .zshrc を
# ホームディレクトリにシンボリックリンクします。
#
# ================================================

# スクリプトのベースディレクトリを決定
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# ターゲットファイルとリンク先
ZPROFILE_SOURCE="${BASE_DIR}/macos/config/shell/.zprofile"
ZPROFILE_DEST="${HOME}/.zprofile"

ZSHRC_SOURCE="${BASE_DIR}/macos/config/shell/.zshrc"
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
if [ ! -L "${ZPROFILE_DEST}" ] || [ "$(readlink "${ZPROFILE_DEST}")" != "${ZPROFILE_SOURCE}" ]; then
    echo "[ERROR] .zprofile symbolic link is incorrect."
    echo "  Expected: ${ZPROFILE_DEST} -> ${ZPROFILE_SOURCE}"
    echo "  Actual: $(readlink "${ZPROFILE_DEST}")"
    verification_failed=true
else
    echo "[SUCCESS] .zprofile symbolic link is correct."
fi

# .zshrc の検証
if [ ! -L "${ZSHRC_DEST}" ] || [ "$(readlink "${ZSHRC_DEST}")" != "${ZSHRC_SOURCE}" ]; then
    echo "[ERROR] .zshrc symbolic link is incorrect."
    echo "  Expected: ${ZSHRC_DEST} -> ${ZSHRC_SOURCE}"
    echo "  Actual: $(readlink "${ZSHRC_DEST}")"
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
