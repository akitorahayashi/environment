#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_ROOT_DIR="$SCRIPT_DIR"

# CI環境かどうかを確認
export IS_CI=${CI:-false}

# リポジトリのルートディレクトリを設定
if [ "$IS_CI" = "true" ] && [ -n "$GITHUB_WORKSPACE" ]; then
    export REPO_ROOT="$GITHUB_WORKSPACE"
else
    export REPO_ROOT="$SCRIPT_DIR"
fi

# CI環境ではスクリプトに実行権限を付与
if [ "$IS_CI" = "true" ]; then
    echo "CI環境のためスクリプトに実行権限を付与します..."
    find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
    echo "スクリプトディレクトリの内容:"
    find "$SCRIPT_DIR/scripts" -type f -name "*.sh" | sort
fi

# ユーティリティのロード
echo "ユーティリティスクリプトをロード中..."
source "$SCRIPT_DIR/scripts/utils/logging.sh" || { 
    echo "❌ logging.shをロードできませんでした。処理を終了します。" 
    exit 1
}
source "$SCRIPT_DIR/scripts/utils/helpers.sh" || echo "警告: helpers.shをロードできませんでした"

# セットアップ関数のロード
echo "セットアップスクリプトをロード中..."
source "$SCRIPT_ROOT_DIR/scripts/setup/homebrew.sh" || echo "警告: homebrew.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/mac.sh" || echo "警告: mac.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/shell.sh" || echo "警告: shell.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/git.sh" || echo "警告: git.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/ruby.sh" || echo "警告: ruby.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/xcode.sh" || echo "警告: xcode.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/flutter.sh" || echo "警告: flutter.shをロードできませんでした"
source "$SCRIPT_ROOT_DIR/scripts/setup/cursor.sh" || echo "警告: cursor.shをロードできませんでした"

# エラー発生時に即座に終了する設定
set -e

# インストール開始時間を記録
start_time=$(date +%s)
echo "Macをセットアップ中..."

main() {
    log_start "開発環境のセットアップを開始します"
    
    # 環境フラグのチェックと関連ユーティリティのロード
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        if [ -f "$SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh" ]; then
            source "$SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh"
            mark_second_run
            log_info "🔍 冪等性テストモード：2回目の実行でインストールされるコンポーネントを検出します"
        else
            log_warning "冪等性テストユーティリティが見つかりません: $SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh"
            export IDEMPOTENT_TEST="false"
        fi
    fi
    
    # セットアップ実行
    install_homebrew
    install_brewfile
    setup_shell_config
    setup_flutter
    install_rosetta
    setup_mac_settings
    setup_git_config
    setup_ssh_agent
    setup_github_cli
    setup_ruby_env
    log_start "Xcodeのインストールを開始します..."
    if ! install_xcode; then
        handle_error "Xcodeのインストールに問題がありました"
    else
        log_success "Xcodeのインストールが完了しました"
    fi
    setup_cursor

    # インストール結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    log_success "セットアップ処理が完了しました！"
    log_success "所要時間: ${elapsed_time}秒"
}

# メイン処理の実行
main
