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

# 冪等性テスト用の変数
declare -g IDEMPOTENT_TEST="${IDEMPOTENT_TEST:-false}"
declare -g IDEMPOTENT_VIOLATIONS=()

# コンポーネントが2回目以降で再インストールされようとしているかチェック
check_idempotence() {
    local component="$1"
    local message="$2"
    
    if [ "${IDEMPOTENT_TEST}" = "true" ]; then
        log_warning "🔍 冪等性違反: ${component} が2回目の実行でインストールを試みています"
        log_warning "🔍 詳細: ${message}"
        IDEMPOTENT_VIOLATIONS+=("${component}: ${message}")
    fi
}

# 冪等性違反をレポート
report_idempotence_violations() {
    if [ "${#IDEMPOTENT_VIOLATIONS[@]}" -gt 0 ]; then
        log_error "==== 冪等性テスト結果: 失敗 ===="
        log_error "以下のコンポーネントが2回目の実行でもインストールを試みています:"
        for violation in "${IDEMPOTENT_VIOLATIONS[@]}"; do
            log_error "- ${violation}"
        done
        return 1
    else
        log_success "==== 冪等性テスト結果: 成功 ===="
        log_success "すべてのコンポーネントが正しく冪等性を維持しています"
        return 0
    fi
}

# 2回目実行を検出するフラグを設定
mark_second_run() {
    export IDEMPOTENT_TEST="true"
    log_info "🔍 冪等性テストモードが有効になりました"
} 