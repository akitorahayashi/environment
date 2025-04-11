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
source "$SCRIPT_ROOT_DIR/scripts/setup/reactnative.sh" || echo "警告: reactnative.shをロードできませんでした"

# エラー発生時に即座に終了する設定
set -e

# インストール開始時間を記録
start_time=$(date +%s)
echo "Macをセットアップ中..."

# インストール処理の本体
main() {
    log_start "開発環境のセットアップを開始します"
    
    # 環境フラグのチェック
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        mark_second_run
        log_info "🔍 冪等性テストモード：2回目の実行でインストールされるコンポーネントを検出します"
    fi
    
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
    
    # React Native環境のセットアップ
    setup_reactnative
    
    # Cursorのセットアップ
    setup_cursor

    # CI環境の場合、検証を実行
    if [ "$IS_CI" = "true" ]; then
        log_start "CI環境での検証を開始します..."
        if [ -f "$REPO_ROOT/.github/workflows/ci_verify.sh" ]; then
            chmod +x "$REPO_ROOT/.github/workflows/ci_verify.sh"
            "$REPO_ROOT/.github/workflows/ci_verify.sh"
            VERIFY_EXIT_CODE=$?
            if [ $VERIFY_EXIT_CODE -ne 0 ]; then
                log_error "CI環境での検証に失敗しました"
                # CI環境では検証失敗でも続行（オプション）
                if [ "$ALLOW_COMPONENT_FAILURE" != "true" ]; then
                    exit $VERIFY_EXIT_CODE
                fi
            else
                log_success "CI環境での検証が正常に完了しました"
            fi
        else
            log_warning "検証スクリプトが見つかりません: $REPO_ROOT/.github/workflows/ci_verify.sh"
        fi
    fi

    # インストール結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    # 実行完了メッセージ
    log_success "すべてのインストールと設定が完了しました！"
    log_success "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"

    # 冪等性レポートの表示（テストモードの場合）
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        report_idempotence_violations
    fi

    # 新しいシェルセッションの開始方法を案内
    if [ "$IS_CI" != "true" ]; then
        log_info "新しい環境設定を適用するには、ターミナルを一度閉じて再度開いてください"
    fi
}

# メイン処理の実行
main
