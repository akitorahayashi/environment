#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# VS Code のセットアップ
setup_vscode() {
    log_start "VS Code のセットアップを開始します..."
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$config_dir" ]; then
        log_warning "設定ディレクトリが見つかりません: $config_dir"
        log_info "VS Code設定のセットアップをスキップします。"
        return 0
    fi

    # VS Code アプリケーションの存在確認
    if ! ls /Applications/Visual\ Studio\ Code.app &>/dev/null; then
        log_warning "Visual Studio Code がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    log_installed "Visual Studio Code"

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
                log_error "VS Code設定ファイル $filename のシンボリックリンク作成に失敗しました。"
                return 1
            fi
        fi
    done
    
    log_success "VS Code設定ファイル ${linked_count}個のシンボリックリンクを作成しました"
    return 0
}

# VS Code環境を検証
verify_vscode_setup() {
    log_start "VS Code環境を検証中..."
    local verification_failed=false
    local config_dir="$REPO_ROOT/config/vscode"
    local vscode_target_dir="$HOME/Library/Application Support/Code/User"

    # アプリケーションがインストールされているかを確認
    if ! ls /Applications/Visual\ Studio\ Code.app &>/dev/null; then
        log_error "Visual Studio Code.appが見つかりません"
        return 1
    fi
    log_installed "Visual Studio Code"

    # リポジトリに設定ファイルがない場合はスキップ
    if [ ! -d "$config_dir" ]; then
        log_info "リポジトリにVS Code設定が見つからないため、設定の検証はスキップします。"
        return 0
    fi

    # 設定ディレクトリの存在確認
    if [ ! -d "$vscode_target_dir" ]; then
        log_error "VS Code設定ディレクトリが作成されていません: $vscode_target_dir"
        log_info "ヒント: setup_vscode() 関数を先に実行してください"
        verification_failed=true
    else
        log_success "VS Code設定ディレクトリが存在します: $vscode_target_dir"

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
                        log_success "VS Code設定ファイル $filename が正しくリンクされています。"
                        ((linked_files++))
                    else
                        log_error "VS Code設定ファイル $filename のリンク先が不正です: $link_target (期待値: $file)"
                        verification_failed=true
                    fi
                else
                    log_error "VS Code設定ファイル $filename のシンボリックリンクが作成されていません。"
                    verification_failed=true
                fi
            fi
        done

        if [ "$linked_files" -eq 0 ]; then
            log_error "VS Code用のシンボリックリンクが一つも作成されていません。"
            verification_failed=true
        fi
    fi

    if [ "$verification_failed" = "true" ]; then
        log_error "VS Code環境の検証に失敗しました"
        return 1
    else
        log_success "VS Code環境の検証が完了しました"
        return 0
    fi
}

# メイン関数
main() {
    log_start "VS Code環境のセットアップを開始します"
    
    setup_vscode
    
    log_success "VS Code環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 