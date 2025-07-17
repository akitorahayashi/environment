#!/bin/bash
set -euo pipefail

# ================================================
# 現在の VSCode 拡張機能リストを取得し、extensions.txt を生成
# ================================================
#
# Usage:
# 1. Grant execution permission:
#    $ chmod +x config/vscode/extensions/backup-extensions.sh
# 2. Run the script:
#    $ ./config/vscode/extensions/backup-extensions.sh
#
# The script will create/update config/vscode/extensions/extensions.txt with the current list of VSCode extensions.
#
# ================================================

# VSCode拡張機能のリストをバックアップするスクリプト
# バックアップファイルのパス
EXT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXT_FILE="$EXT_DIR/extensions.txt"

# VSCodeコマンドの検出
if command -v code >/dev/null 2>&1; then
  CODE_CMD="code"
elif command -v code-insiders >/dev/null 2>&1; then
  CODE_CMD="code-insiders"
else
  echo "VSCodeのコマンド(code または code-insiders)が見つかりません。PATHを確認してください。" >&2
  exit 1
fi

# 拡張機能リストの取得と保存
$CODE_CMD --list-extensions > "$EXT_FILE"
echo "VSCode拡張機能のリストをバックアップしました: $EXT_FILE"
