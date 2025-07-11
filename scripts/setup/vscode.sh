#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh" || exit 2

# インストール実行フラグ
installation_performed=false

# VS Code のセットアップ
setup_vscode() {
    echo ""
    echo "==== Start: VS Code のセットアップを開始します... ===="
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        echo "[WARN] 設定ディレクトリが見つかりません: $config_dir"
        echo "[INFO] VS Code設定のセットアップをスキップします。"
        return 0
    fi

    # VS Code アプリケーションの存在確認
    if ! ls /Applications/Visual\ Studio\ Code.app &>/dev/null; then
        echo "[WARN] Visual Studio Code がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    echo "[OK] Visual Studio Code ... already installed"

    # ターゲットディレクトリの作成
    mkdir -p "$vscode_target_dir"

    # 設定ファイルのシンボリックリンクを作成
    local linked_count=0
    shopt -s nullglob
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            local filename
            filename=$(basename "$file")
            local target_file="$vscode_target_dir/$filename"
            
            # 既存のファイルを削除
            if [ -f "$target_file" ] || [ -L "$target_file" ]; then
                rm -f "$target_file"
            fi
            
            # シンボリックリンクの作成
            if ln -s "$file" "$target_file"; then
                ((linked_count++))
            else
                echo "[ERROR] VS Code設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                exit 2
            fi
        fi
    done
    
    echo "[OK] VS Code設定ファイル ${linked_count}個のシンボリックリンクを作成しました"
    return 0
}

# VS Code環境を検証
verify_vscode_setup() {
    echo ""
    echo "==== Start: VS Code環境を検証中... ===="
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # アプリケーションがインストールされているかを確認
    if ! ls /Applications/Visual\ Studio\ Code.app &>/dev/null; then
        echo "[ERROR] Visual Studio Code.appが見つかりません"
        return 1
    fi
    echo "[OK] Visual Studio Code ... already installed"

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        echo "[INFO] リポジトリにVS Code設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

    # 設定ディレクトリの存在確認
    if [ ! -d "$vscode_target_dir" ]; then
        echo "[ERROR] VS Code設定ディレクトリが作成されていません: $vscode_target_dir"
        echo "[INFO] ヒント: setup_vscode() 関数を先に実行してください"
        verification_failed=true
    else
        echo "[OK] VS Code設定ディレクトリが存在します: $vscode_target_dir"

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
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] VS Code環境の検証に失敗しました"
        return 1
    else
        echo "[OK] VS Code環境の検証が完了しました"
        return 0
    fi
}

# メイン関数
main() {
    echo ""
    echo "==== Start: VS Code環境のセットアップを開始します ===="
    
    setup_vscode
    
    echo "[OK] VS Code環境のセットアップが完了しました"
    
    # 終了ステータスの決定
    if [ "$installation_performed" = "true" ]; then
        exit 0  # インストール実行済み
    else
        exit 1  # インストール不要（冪等性保持）
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 