#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/logging.sh"

# パスワードプロンプトを表示する
prompt_for_sudo() {
    local reason="$1"
    echo ""
    echo "⚠️ 管理者権限が必要な操作を行います: $reason"
    echo "🔒 Macロック解除時のパスワードを入力してください"
    echo ""
} 

# コマンドが存在するかチェックする
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

