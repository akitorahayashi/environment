#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_ROOT_DIR="$SCRIPT_DIR"  # スクリプトのルートディレクトリを保存

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
source "$SCRIPT_ROOT_DIR/scripts/setup/neovim.sh" || echo "警告: neovim.shをロードできませんでした"

# エラー発生時に即座に終了する設定
set -e

# インストール開始時間を記録
start_time=$(date +%s)
echo "Macをセットアップ中..."

# インストール処理の本体
main() {
    log_start "開発環境のセットアップを開始します"
    
    # 環境フラグのチェックと関連ユーティリティのロード
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then # IDEMPOTENT_TEST が有効な場合のみ
        if [ -f "$SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh" ]; then
            source "$SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh"
            mark_second_run # source した後に呼び出す
            log_info "🔍 冪等性テストモード：2回目の実行でインストールされるコンポーネントを検出します"
        else
            log_warning "冪等性テストユーティリティが見つかりません: $SCRIPT_ROOT_DIR/scripts/utils/idempotency_utils.sh"
            export IDEMPOTENT_TEST="false" # 見つからない場合はテストを無効化
        fi
    fi
    
    # --- Essential Setup for Flutter Debugging ---
    install_homebrew
    install_brewfile
    setup_shell_config
    setup_flutter # Flutter setup must run
    # ----------------------------------------------

    # --- Temporarily Disabled Steps --- 
    # Mac関連のセットアップ
    # install_rosetta
    # setup_mac_settings
    
    # 基本環境のセットアップ
    # setup_shell_config # Already done above
    
    # Gitと認証関連のセットアップ
    # setup_git_config
    # setup_ssh_agent
    # setup_github_cli
    
    # パッケージとプログラミング言語環境のインストール
    # setup_ruby_env
    
    # Xcodeのインストール
    # log_start "Xcodeのインストールを開始します..."
    # if ! install_xcode; then
    #     handle_error "Xcodeのインストールに問題がありました"
    # else
    #     log_success "Xcodeのインストールが完了しました"
    # fi

    # Flutter関連のセットアップ
    # setup_flutter # Moved up
    
    # Cursorのセットアップ
    # setup_cursor

    # Neovim環境のセットアップ (検証するので有効化)
    setup_neovim_env
    # --- End of Temporarily Disabled Steps ---

    # CI環境の場合、検証を実行 (This block might also be temporarily disabled if not needed)
    # if [ "$IS_CI" = "true" ]; then
    #    ...
    # fi

    # インストール結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    # 実行完了メッセージ
    log_success "セットアップ処理 (デバッグモード) が完了しました！"
    log_success "所要時間: ${elapsed_time}秒"

    # 冪等性レポートの表示（テストモードの場合）
    # if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
    #     report_idempotence_violations
    # fi

    # 新しいシェルセッションの開始方法を案内
    # if [ "$IS_CI" != "true" ]; then
    #     log_info "新しい環境設定を適用するには、ターミナルを再起動するか、'source ~/.zprofile' を実行してください。"
    # fi
}

# メイン処理の実行
main
