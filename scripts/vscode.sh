#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 依存関係をインストール
install_dependencies() {
    echo "[INFO] 依存関係をチェック・インストールします: visual-studio-code"
    if ! brew list --cask visual-studio-code &> /dev/null; then
        brew install --cask visual-studio-code
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi
}

main() {
    install_dependencies
    echo "[Start] VS Code のセットアップを開始します..."
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        echo "[WARN] 設定ディレクトリが見つかりません: $config_dir"
        echo "[INFO] VS Code設定のセットアップをスキップします。"
        return 0
    fi

    # VS Code アプリケーションの存在確認
    if [ ! -d "/Applications/Visual Studio Code.app" ]; then
        echo "[WARN] Visual Studio Code がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    echo "[SUCCESS] Visual Studio Code はすでにインストールされています"

    # ターゲットディレクトリの作成
    mkdir -p "$vscode_target_dir"

    # 設定ファイルのシンボリックリンクを作成
    shopt -s nullglob
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            local filename
            filename=$(basename "$file")
            local target_file="$vscode_target_dir/$filename"
            
            # シンボリックリンクの作成
            if ln -sf "$file" "$target_file"; then
                echo "[SUCCESS] VS Code設定ファイル $filename のシンボリックリンクを作成しました。"
            else
                echo "[ERROR] VS Code設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                exit 1
            fi
        fi
    done
    shopt -u nullglob
    
    echo "[SUCCESS] VS Code環境のセットアップが完了しました"

    verify_vscode_setup
}

verify_vscode_setup() {
    echo ""
    echo "==== Start: VS Code環境を検証中... ===="
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        echo "[INFO] リポジトリにVS Code設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

    # 実際にシンボリックリンクが作成されているかを確認
    local linked_files=0
    shopt -s nullglob
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            local filename
            filename=$(basename "$file")
            local target_file="$vscode_target_dir/$filename"
            
            if [ -L "$target_file" ]; then
                local link_target
                link_target=$(readlink "$target_file")
                if [ "$link_target" = "$file" ]; then
                    echo "[OK] VS Code設定ファイル $filename が正しくリンクされています。"
                    ((linked_files++))
                else
                    echo "[ERROR] VS Code設定ファイル $filename のリンク先が不正です: $link_target (期待値: $file)"
                    verification_failed=true
                fi
            else
                echo "[ERROR] VS Code設定ファイル $filename のシンボリックリンクが作成されていません。"
                verification_failed=true
            fi
        fi
    done

    if [ "$linked_files" -eq 0 ]; then
        echo "[ERROR] VS Code用のシンボリックリンクが一つも作成されていません。"
        verification_failed=true
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] VS Code環境の検証に失敗しました"
        return 1
    else
        echo "[OK] VS Code環境の検証が完了しました"
        return 0
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi