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

# シンボリックリンクを安全に作成する関数
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    
    # ソースファイルが存在するか確認
    if [ ! -f "$source_file" ] && [ ! -d "$source_file" ]; then
        handle_error "$source_file が見つかりません"
    fi
    
    # 既存のファイルやシンボリックリンクが存在する場合は削除
    if [ -L "$target_file" ] || [ -f "$target_file" ] || [ -d "$target_file" ]; then
        rm -rf "$target_file"
    fi
    
    # シンボリックリンクを作成
    ln -sf "$source_file" "$target_file"
    log_success "$(basename "$target_file") のシンボリックリンクを作成しました"
} 