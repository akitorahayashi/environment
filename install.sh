#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$SCRIPT_DIR"  # 元のSCRIPT_DIRを保存

# CI環境かどうかを確認
export IS_CI=${CI:-false}

# リポジトリのルートディレクトリを設定
if [ "$IS_CI" = "true" ] && [ -n "$GITHUB_WORKSPACE" ]; then
    export REPO_ROOT="$GITHUB_WORKSPACE"
else
    export REPO_ROOT="$HOME/environment"
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
source "$ROOT_DIR/scripts/setup/homebrew.sh" || echo "警告: homebrew.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/mac.sh" || echo "警告: mac.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/shell.sh" || echo "警告: shell.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/git.sh" || echo "警告: git.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/ruby.sh" || echo "警告: ruby.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/xcode.sh" || echo "警告: xcode.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/android.sh" || echo "警告: android.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/flutter.sh" || echo "警告: flutter.shをロードできませんでした"
source "$ROOT_DIR/scripts/setup/cursor.sh" || echo "警告: cursor.shをロードできませんでした"

# エラー発生時に即座に終了する設定
set -e

# インストール開始時間
start_time=$(date +%s)
echo "Macをセットアップ中..."

# メインのインストール処理
main() {
    log_start "開発環境のセットアップを開始します"
    
    # Mac関連のセットアップ
    install_rosetta
    setup_mac_settings
    
    # 基本環境のセットアップ
    install_homebrew
    setup_shell_config
    
    # Gitと認証関連のセットアップ
    setup_git_config
    setup_ssh_agent
    setup_github_cli
    
    # パッケージとプログラミング言語環境のインストール
    install_brewfile
    setup_ruby_env
    
    # Xcodeのインストール
    log_start "Xcodeのインストールを開始します..."
    if ! install_xcode; then
        handle_error "Xcodeのインストールに問題がありました"
    else
        log_success "Xcodeのインストールが完了しました"
    fi

    # Flutter関連のセットアップ
    setup_flutter
    
    # Cursorのセットアップ
    setup_cursor

    # インストール結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    # 実行完了メッセージ
    log_success "すべてのインストールと設定が完了しました！"
    log_success "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"

    # 新しいシェルセッションを開始
    [ "$IS_CI" != "true" ] && exec $SHELL -l
}

# メイン処理の実行
main
