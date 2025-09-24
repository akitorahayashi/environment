#!/bin/bash
set -euo pipefail

# Get the configuration directory path from script arguments
CONFIG_DIR="$1"
if [ -z "$CONFIG_DIR" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# ================================================
# 現在の VSCode 拡張機能リストを取得し、extensions.json を生成
# ================================================
#
# Usage:
# 1. Grant execution permission:
#    $ chmod +x ansible/utils/backup-extensions.sh
# 2. Run the script:
#    $ ./ansible/utils/backup-extensions.sh config/common
#
# The script will create/update config/common/vscode/extensions/extensions.json with the current list of VSCode extensions.
#
# ================================================

# VSCode拡張機能のリストをバックアップするスクリプト
# バックアップファイルのパス

# CI環境かどうかで出力先を決定
if [ "${CI:-false}" = "true" ]; then
  EXT_FILE="/tmp/extensions.json"
else
  EXT_FILE="$CONFIG_DIR/vscode/extensions.json"
  mkdir -p "$(dirname "$EXT_FILE")"
fi

# VSCodeコマンドの検出
if command -v code >/dev/null 2>&1; then
  CODE_CMD="code"
elif [ -f "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" ]; then
  CODE_CMD="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
elif command -v code-insiders >/dev/null 2>&1; then
  CODE_CMD="code-insiders"
else
  echo "VSCodeのコマンド(code または code-insiders)が見つかりません。" >&2
  exit 1
fi

# 拡張機能リストの取得と保存
echo "VSCode拡張機能リストを取得中..."
if ! extensions=$("$CODE_CMD" --list-extensions 2>&1); then
  echo "❌ VSCode拡張機能の取得に失敗しました。" >&2
  echo "   考えられる原因:" >&2
  echo "   - VSCodeが起動中の場合、一度VSCodeを終了してから再度実行してください" >&2
  echo "   - VSCodeのインストールに問題がある場合" >&2
  echo "   - コマンド: $CODE_CMD --list-extensions" >&2
  echo "   エラー出力: $extensions" >&2
  exit 1
fi

json="{\"extensions\": ["
for ext in $extensions; do
  json+="\"$ext\","
done
json=${json%,}
json+="]}"
echo "$json" | python3 -m json.tool > "$EXT_FILE"
echo "VSCode拡張機能のリストをバックアップしました: $EXT_FILE"