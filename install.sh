#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_ROOT_DIR="$SCRIPT_DIR"

# CI環境かどうかを確認
export IS_CI=${CI:-false}

# コマンドライン引数の処理
while [[ $# -gt 0 ]]; do
    case $1 in
        --idempotent-test)
            export IDEMPOTENT_TEST=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Available option: --idempotent-test"
            exit 1
            ;;
    esac
done

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
    if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
        echo "==== Start: 冪等性テストを開始します ===="
    else
        echo "==== Start: 開発環境のセットアップを開始します ===="
    fi
    
    # セットアップスクリプトの実行と終了ステータスの収集
    declare -a scripts=(
        "shell:$SCRIPT_ROOT_DIR/scripts/shell.sh"
        "homebrew:$SCRIPT_ROOT_DIR/scripts/homebrew.sh"
        "mac:$SCRIPT_ROOT_DIR/scripts/macos.sh"
        "git:$SCRIPT_ROOT_DIR/scripts/git.sh"
        "cursor:$SCRIPT_ROOT_DIR/scripts/cursor.sh"
        "vscode:$SCRIPT_ROOT_DIR/scripts/vscode.sh"
        "ruby:$SCRIPT_ROOT_DIR/scripts/ruby.sh"
        "python:$SCRIPT_ROOT_DIR/scripts/python.sh"
        "flutter:$SCRIPT_ROOT_DIR/scripts/flutter.sh"
        "node:$SCRIPT_ROOT_DIR/scripts/node.sh"
    )
    
    local has_error=false
    local idempotent_violations=()
    
    for script_entry in "${scripts[@]}"; do
        local script_name="${script_entry%%:*}"
        local script_path="${script_entry#*:}"
        
        echo "==== Processing:  $script_name"
        
        # スクリプトを実行して出力を取得
        set +e
        local output=$("${script_path}" 2>&1)
        local exit_code=$?
        set -e
        
        # 通常の出力を表示
        echo "$output"
        
        # エラーチェック
        if [ $exit_code -ne 0 ]; then
            echo "[ERROR] $script_name: エラー発生 (exit code: $exit_code)"
            has_error=true
            continue
        fi
        
        # INSTALL_PERFORMEDの有無で冪等性を判断
        if echo "$output" | grep -q "INSTALL_PERFORMED"; then
            echo "[OK] $script_name: インストール実行済み"
            if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
                idempotent_violations+=("$script_name")
            fi
        else
            if [ "${IDEMPOTENT_TEST:-false}" = "true" ]; then
                echo "[OK] $script_name: 冪等性が保たれています"
            fi
        fi
    done
    
    # 結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))
    
    if [ "$has_error" = "true" ]; then
        echo "[ERROR] セットアップ処理中にエラーが発生しました"
        echo "[ERROR] 所要時間: ${elapsed_time}秒"
        exit 1
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
        else
            echo "[OK] セットアップ処理が完了しました！"
            echo "[OK] 所要時間: ${elapsed_time}秒"
        fi
        exit 0
    fi
}

# メイン処理の実行
main
