#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Cursor のセットアップ (stowを使用)
setup_cursor() {
    log_start "Cursor のセットアップを開始します (stow)..."
    local stow_config_dir="$REPO_ROOT/config"
    local stow_package="cursor"
    # stow のターゲットディレクトリ ($HOME/Library/...) を定義
    local target_base_dir="$HOME/Library/Application Support/Cursor"
    local target_user_dir="$target_base_dir/User"

    # Cursor アプリケーションの存在確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return 0 # インストールされていなければエラーではない
    fi
    log_installed "Cursor"

    # リポジトリに設定ファイルがあるか確認
    if [ ! -d "$stow_config_dir/$stow_package" ]; then
        log_warning "設定ディレクトリが見つかりません: $stow_config_dir/$stow_package"
        log_info "Cursor設定のセットアップをスキップします。"
        return 0
    fi

    # stow のターゲットディレクトリの親が存在することを確認
    log_info "Cursor設定ディレクトリを作成します (存在しない場合): $target_user_dir"
    mkdir -p "$target_user_dir"

    # stow コマンドでシンボリックリンクを作成/更新
    # ターゲットは設定ファイルが置かれるべき User ディレクトリ
    log_info "'$stow_package' パッケージを '$stow_config_dir' から '$target_user_dir' にstowします..."
    # 注意: stow は通常ターゲットディレクトリ直下にリンクを作成する。
    # $REPO_ROOT/config/cursor/settings.json -> $target_user_dir/settings.json となる。
    if stow --dir="$stow_config_dir" --target="$target_user_dir" --restow --adopt "$stow_package"; then
        log_success "Cursor設定ファイルのシンボリックリンクを作成/更新しました。"
    else
        log_error "Cursor設定ファイルのシンボリックリンク作成/更新に失敗しました。"
        # ログに競合の可能性などを追記しても良い
        return 1
    fi

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
        # config/cursor 内の想定されるファイルを確認
        # (ここでは代表的なもののみ。必要に応じて増やす)
        SETTINGS_FILES=("settings.json" "keybindings.json" "extensions.json")
        for file in "${SETTINGS_FILES[@]}"; do
             # リポジトリ側にファイルが存在するか
            if [ -f "$config_dir/$file" ]; then
                 # ターゲット側にシンボリックリンクが存在するか
                if [ -L "$target_dir/$file" ]; then
                     # リンク先が正しいか (簡易チェック)
                    local link_target=$(readlink "$target_dir/$file")
                    if [[ "$link_target" == *"$config_dir/$file"* ]]; then
                         log_success "設定ファイル $file が正しくリンクされています。"
                    else
                         log_error "設定ファイル $file のリンク先が不正です: $link_target"
                         verification_failed=true
                    fi
                else
                    log_error "設定ファイル $file がシンボリックリンクとして存在しません。"
                    verification_failed=true
                fi
            else
                 log_info "リポジトリに $file が見つからないため、検証をスキップします。"
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