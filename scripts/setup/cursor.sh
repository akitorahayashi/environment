#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh" || exit 2

# インストール実行フラグ
installation_performed=false

# Cursor のセットアップ
setup_cursor() {
    echo "==== Start: "Cursor のセットアップを開始します...""
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        echo "[WARN] "設定ディレクトリが見つかりません: $config_dir""
        echo "[INFO] "Cursor設定のセットアップをスキップします。""
        return 0
    fi

    # Cursor アプリケーションの存在確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        echo "[WARN] "Cursor がインストールされていません。スキップします。""
        return 0 # インストールされていなければエラーではない
    fi
    echo "[OK] "Cursor""

    # ターゲットディレクトリの作成
    mkdir -p "$cursor_target_dir"

    # 設定ファイルのシンボリックリンクを作成
    shopt -s nullglob   # マッチしない場合は展開結果を空にする
    local linked_count=0
    for file in "$config_dir"/*; do
        if [[ -f "$file" ]]; then
            local filename
            filename=$(basename "$file")  
            local target_file="$cursor_target_dir/$filename"
            
            # 既存のファイルを削除
            if [ -f "$target_file" ] || [ -L "$target_file" ]; then
                rm -f "$target_file"
            fi
            
            # シンボリックリンクの作成
            if ln -s "$file" "$target_file"; then
                ((linked_count++))
            else
                echo "[ERROR] "Cursor設定ファイル $filename のシンボリックリンク作成に失敗しました。""
                exit 2
            fi
        fi
    done
    shopt -u nullglob
    
    echo "[SUCCESS] "Cursor設定ファイル ${linked_count}個のシンボリックリンクを作成しました""
    return 0
}

# Cursor環境を検証
verify_cursor_setup() {
    echo "==== Start: "Cursor環境を検証中...""
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # アプリケーションがインストールされているかを確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        echo "[ERROR] "Cursor.appが見つかりません""
        return 1
    fi
    echo "[OK] "Cursor""

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        echo "[INFO] "リポジトリにCursor設定が見つからないため、設定の検証はスキップします。""
        return 0
    fi

    # 設定ディレクトリの存在確認
    if [ ! -d "$cursor_target_dir" ]; then
        echo "[ERROR] "Cursor設定ディレクトリが作成されていません: $cursor_target_dir""
        verification_failed=true
    else
        echo "[SUCCESS] "Cursor設定ディレクトリが存在します: $cursor_target_dir""

        # 実際にシンボリックリンクが作成されているかを確認
        shopt -s nullglob   # マッチしない場合は展開結果を空にする
        local linked_files=0
        for file in "$config_dir"/*; do
            if [[ -f "$file" ]]; then
                local filename
                filename=$(basename "$file")
                local target_file="$cursor_target_dir/$filename"
                
                if [ -L "$target_file" ]; then
                    local link_target
                    link_target=$(readlink "$target_file")
                    if [ "$link_target" = "$file" ]; then
                        echo "[SUCCESS] "Cursor設定ファイル $filename が正しくリンクされています。""
                        ((linked_files++))
                    else
                        echo "[ERROR] "Cursor設定ファイル $filename のリンク先が不正です: $link_target (期待値: $file)""
                        verification_failed=true
                    fi
                else
                    echo "[ERROR] "Cursor設定ファイル $filename のシンボリックリンクが作成されていません。""
                    verification_failed=true
                fi
            fi
        done
        shopt -u nullglob

        if [ "$linked_files" -eq 0 ]; then
            echo "[ERROR] "Cursor用のシンボリックリンクが一つも作成されていません。""
            verification_failed=true
        fi
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] "Cursor環境の検証に失敗しました""
        return 1
    else
        echo "[SUCCESS] "Cursor環境の検証が完了しました""
        return 0
    fi
}

# メイン関数
main() {
    echo "==== Start: "Cursor環境のセットアップを開始します""
    
    setup_cursor
    
    echo "[SUCCESS] "Cursor環境のセットアップが完了しました""
    
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
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 