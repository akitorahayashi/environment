#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# シェル設定ファイルを適用する
setup_shell_config() {
    log_start "シェルの設定を適用中..."
    
    # ディレクトリとファイルの存在確認
    if [[ ! -d "$REPO_ROOT/shell" ]]; then
        handle_error "$REPO_ROOT/shell ディレクトリが見つかりません"
    fi
    
    if [[ ! -f "$REPO_ROOT/shell/.zprofile" ]]; then
        handle_error "$REPO_ROOT/shell/.zprofile ファイルが見つかりません"
    fi
    
    # .zprofileファイルのシンボリックリンクを作成
    create_symlink "$REPO_ROOT/shell/.zprofile" "$HOME/.zprofile"
    
    # 設定を反映（CI環境ではスキップ）
    if [ "$IS_CI" != "true" ] && [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi
    
    log_success "シェルの設定を適用完了"
} 