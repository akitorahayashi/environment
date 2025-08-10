#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_ROOT_DIR="$SCRIPT_DIR"

# リポジトリのルートディレクトリを設定
if [ "${CI}" = "true" ] && [ -n "$GITHUB_WORKSPACE" ]; then
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
    
    # セットアップスクリプトの実行
    declare -a scripts=(
        "homebrew:$SCRIPT_ROOT_DIR/scripts/homebrew.sh"
        "git:$SCRIPT_ROOT_DIR/scripts/git.sh"
        "vscode:$SCRIPT_ROOT_DIR/scripts/vscode.sh"
        "ruby:$SCRIPT_ROOT_DIR/scripts/ruby.sh"
        "python:$SCRIPT_ROOT_DIR/scripts/python.sh"
        "java:$SCRIPT_ROOT_DIR/scripts/java.sh"
        "flutter:$SCRIPT_ROOT_DIR/scripts/flutter.sh"
        "node:$SCRIPT_ROOT_DIR/scripts/node.sh"
    )
    
    for script_entry in "${scripts[@]}"; do
        local script_name="${script_entry%%:*}"
        local script_path="${script_entry#*:}"
        
        echo "==== Processing:  $script_name"
        
        # スクリプト存在 & 実行権限確認
        if [[ ! -x "$script_path" ]]; then
            echo "[ERROR] $script_name: スクリプトが見つからないか実行権限がありません ($script_path)"
            exit 1
        fi
        # スクリプトを実行
        if ! "${script_path}"; then
            echo "[ERROR] $script_name: エラー発生"
            exit 1
        fi
    done
    
    # 結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    
    echo "[OK] セットアップ処理が完了しました！"
    echo "[OK] 所要時間: ${elapsed_time}秒"
    exit 0
}

# メイン処理の実行
main
