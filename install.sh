#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    chmod +x "$SCRIPT_DIR/scripts/setup/"*.sh
    chmod +x "$SCRIPT_DIR/scripts/utils/"*.sh
fi

# ユーティリティのロード
source "$SCRIPT_DIR/scripts/utils/logging.sh"
source "$SCRIPT_DIR/scripts/utils/helpers.sh"

# Rosetta関数を直接定義（CI環境での問題回避のため）
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Mac のチップモデルを取得
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        log_info " 🖥  Mac Model: $MAC_MODEL"

        # M1 または M2 の場合のみ Rosetta 2 をインストール
        if [[ "$MAC_MODEL" == *"M1"* || "$MAC_MODEL" == *"M2"* ]]; then
            # すでに Rosetta 2 がインストールされているかチェック
            if pgrep oahd >/dev/null 2>&1; then
                log_success "Rosetta 2 はすでにインストール済み"
                return
            fi

            # Rosetta 2 をインストール
            log_start "Rosetta 2 を $MAC_MODEL 向けにインストール中..."
            if [ "$IS_CI" = "true" ]; then
                # CI環境では非対話型でインストール
                softwareupdate --install-rosetta --agree-to-license || true
            else
                softwareupdate --install-rosetta --agree-to-license
            fi

            # インストールの成否をチェック
            if pgrep oahd >/dev/null 2>&1; then
                log_success "Rosetta 2 のインストールが完了しました"
            else
                handle_error "Rosetta 2 のインストールに失敗しました"
            fi
        else
            log_success "この Mac ($MAC_MODEL) には Rosetta 2 は不要"
        fi
    else
        log_success "この Mac は Apple Silicon ではないため、Rosetta 2 は不要"
    fi
}

# セットアップ関数のロード
source "$SCRIPT_DIR/scripts/setup/homebrew.sh"
source "$SCRIPT_DIR/scripts/setup/mac.sh"
source "$SCRIPT_DIR/scripts/setup/shell.sh"
source "$SCRIPT_DIR/scripts/setup/git.sh"
source "$SCRIPT_DIR/scripts/setup/ruby.sh"
source "$SCRIPT_DIR/scripts/setup/xcode.sh"
source "$SCRIPT_DIR/scripts/setup/android.sh"
source "$SCRIPT_DIR/scripts/setup/flutter.sh"
source "$SCRIPT_DIR/scripts/setup/cursor.sh"

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
    check_critical_packages
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
    exec $SHELL -l
}

# メイン処理の実行
main
