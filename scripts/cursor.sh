#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    echo "[Start] Cursor のセットアップを開始します..."
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        echo "[WARN] 設定ディレクトリが見つかりません: $config_dir"
        echo "[INFO] Cursor設定のセットアップをスキップします。"
        return 0
    fi

    # Cursor アプリケーションの存在確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        echo "[WARN] Cursor がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    echo "[OK] Cursor"

    # ターゲットディレクトリの作成
    mkdir -p "$cursor_target_dir"

    # 設定ファイルのシンボリックリンクを作成
    shopt -s nullglob
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            local filename
            filename=$(basename "$file")
            local target_file="$cursor_target_dir/$filename"
            
            # シンボリックリンクの作成
            if ln -sf "$file" "$target_file"; then
                echo "[SUCCESS] Cursor設定ファイル $filename のシンボリックリンクを作成しました。"
            else
                echo "[ERROR] Cursor設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                exit 1
            fi
        fi
    done

    echo "[SUCCESS] Cursor環境のセットアップが完了しました"

    verify_cursor_setup
}

verify_cursor_setup() {
    echo "==== Start: Cursor環境を検証中... ===="
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local cursor_target_dir="$HOME/Library/Application Support/Cursor/User"

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        echo "[INFO] リポジトリにCursor設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

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
                    echo "[SUCCESS] Cursor設定ファイル $filename が正しくリンクされています。"
                    ((linked_files++))
                else
                    echo "[ERROR] Cursor設定ファイル $filename のリンク先が不正です: $link_target (期待値: $file)"
                    verification_failed=true
                fi
            else
                echo "[ERROR] Cursor設定ファイル $filename のシンボリックリンクが作成されていません。"
                verification_failed=true
            fi
        fi
    done
    shopt -u nullglob

    if [ "$linked_files" -eq 0 ]; then
        echo "[ERROR] Cursor用のシンボリックリンクが一つも作成されていません。"
        verification_failed=true
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Cursor環境の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] Cursor環境の検証が完了しました"
        return 0
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi