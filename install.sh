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

# セットアップスクリプトに実行権限を付与
echo "セットアップスクリプトに実行権限を付与します..."
find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \; 2>/dev/null || true
echo "スクリプトディレクトリの内容:"
find "$SCRIPT_DIR/scripts" -type f -name "*.sh" | sort

# エラー発生時に即座に終了する設定
set -e

# インストール開始時間を記録
start_time=$(date +%s)
echo "Macをセットアップ中..."

main() {
    echo ""
    echo "==== Start: 開発環境のセットアップを開始します ===="
    
    # セットアップスクリプトの実行と終了ステータスの収集
    declare -a scripts=(
        "shell:$SCRIPT_ROOT_DIR/scripts/shell.sh"
        "homebrew:$SCRIPT_ROOT_DIR/scripts/homebrew.sh"
        "mac:$SCRIPT_ROOT_DIR/scripts/mac.sh"
        "git:$SCRIPT_ROOT_DIR/scripts/git.sh"
        "cursor:$SCRIPT_ROOT_DIR/scripts/cursor.sh"
        "vscode:$SCRIPT_ROOT_DIR/scripts/vscode.sh"
        "ruby:$SCRIPT_ROOT_DIR/scripts/ruby.sh"
        "flutter:$SCRIPT_ROOT_DIR/scripts/flutter.sh"
        "node:$SCRIPT_ROOT_DIR/scripts/node.sh"
    )
    
    local has_error=false
    local idempotent_violations=()
    
    for script_entry in "${scripts[@]}"; do
        local script_name="${script_entry%%:*}"
        local script_path="${script_entry#*:}"
        
        # 一時的に errexit を無効にし、スクリプトの戻り値を取得する
        set +e
        "${script_path}"
        local exit_code=$?
        # errexit を再度有効化
        set -e
        
        case $exit_code in
            0)
                echo "[OK] $script_name: インストール実行済み"
                if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
                    idempotent_violations+=("$script_name")
                fi
                ;;
            1)
                echo "[OK] $script_name: 冪等性が保たれています"
                ;;
            2)
                echo "[ERROR] $script_name: エラー発生"
                has_error=true
                ;;
            *)
                echo "[ERROR] $script_name: 不明な終了ステータス ($exit_code)"
                has_error=true
                ;;
        esac
    done
    
    # 結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    
    if [ "$has_error" = "true" ]; then
        echo "[ERROR] セットアップ処理中にエラーが発生しました"
        echo "[ERROR] 所要時間: ${elapsed_time}秒"
        exit 2
    elif [ "${IDEMPOTENT_TEST:-false}" = "true" ] && [ ${#idempotent_violations[@]} -gt 0 ]; then
        echo "[ERROR] ==== 冪等性テスト結果: 失敗 ===="
        echo "[ERROR] 以下のコンポーネントが2回目の実行でもインストールを試みています:"
        for violation in "${idempotent_violations[@]}"; do
            echo "[ERROR] - $violation"
        done
        echo "[ERROR] 所要時間: ${elapsed_time}秒"
        exit 1
    else
        if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
            echo "[OK] ==== 冪等性テスト結果: 成功 ===="
            echo "[OK] すべてのコンポーネントが正しく冪等性を維持しています"
            echo "[OK] 所要時間: ${elapsed_time}秒"
            set +e  # 冪等性テスト成功時は set -e を無効化
            exit 1
        fi
        echo "[OK] セットアップ処理が完了しました！"
        echo "[OK] 所要時間: ${elapsed_time}秒"
        exit 0
    fi
}

# メイン処理の実行
main
