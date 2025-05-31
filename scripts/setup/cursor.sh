#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Cursor のセットアップ
setup_cursor() {
    log_start "Cursor のセットアップを開始します..."
    local config_dir="$REPO_ROOT/config/cursor"
    local target_base_dir="$HOME/Library/Application Support/Cursor"
    local target_user_dir="$target_base_dir/User"

    # Cursor アプリケーションの存在確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    log_installed "Cursor"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        log_warning "設定ディレクトリが見つかりません: $config_dir"
        log_info "Cursor設定のセットアップをスキップします。"
        return 0
    fi

    # ターゲットディレクトリの作成
    log_info "Cursor設定ディレクトリを作成します (存在しない場合): $target_user_dir"
    mkdir -p "$target_user_dir"

    # 設定ファイルのシンボリックリンクを作成
    for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file")
            local target_file="$target_user_dir/$filename"
            
            # 既存のファイルのバックアップ
            if [ -f "$target_file" ] || [ -L "$target_file" ]; then
                log_info "既存の設定ファイルをバックアップします: $target_file"
                mv "$target_file" "$target_file.backup"
            fi
            
            # シンボリックリンクの作成
            log_info "設定ファイルのシンボリックリンクを作成します: $filename"
            if ln -s "$file" "$target_file"; then
                log_success "設定ファイル $filename のシンボリックリンクを作成しました。"
            else
                log_error "設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                return 1
            fi
        fi
    done

    log_success "Cursor のセットアップ完了"
    return 0
}

# Cursor環境を検証
verify_cursor_setup() {
    log_start "Cursor環境を検証中..."
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/cursor"
    local target_dir="$HOME/Library/Application Support/Cursor/User"

    # アプリケーションを確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_error "Cursor.appが見つかりません"
        return 1 # アプリがないと検証できない
    else
        log_installed "Cursor"
    fi

    # リポジトリに設定ファイルが存在する場合のみ検証
    if [ ! -d "$config_dir" ]; then
        log_info "リポジトリにCursor設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

    # 設定ディレクトリの存在確認
    if [ ! -d "$target_dir" ]; then
        log_error "Cursor設定ディレクトリが見つかりません: $target_dir"
        verification_failed=true
    else
        log_success "Cursor設定ディレクトリが存在します: $target_dir"

        # 設定ファイルのシンボリックリンクを確認
        for file in "$config_dir"/*; do
            if [ -f "$file" ]; then
                local filename
                filename=$(basename "$file")
                local target_file="$target_dir/$filename"
                
                if [ -L "$target_file" ]; then
                    local link_target
                    link_target=$(readlink "$target_file")
                    if [ "$link_target" = "$file" ]; then
                        log_success "設定ファイル $filename が正しくリンクされています。"
                    else
                        log_error "設定ファイル $filename のリンク先が不正です: $link_target"
                        verification_failed=true
                    fi
                else
                    log_error "設定ファイル $filename がシンボリックリンクとして存在しません。"
                    verification_failed=true
                fi
            fi
        done
    fi

    if [ "$verification_failed" = "true" ]; then
        log_error "Cursor環境の検証に失敗しました"
        return 1
    else
        log_success "Cursor環境の検証が完了しました"
        return 0
    fi
}

# メイン関数
main() {
    log_start "Cursor環境のセットアップを開始します"
    
    setup_cursor
    
    log_success "Cursor環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 