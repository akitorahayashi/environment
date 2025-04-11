#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# シェル設定ファイルを適用する
setup_shell_config() {
    log_start "シェルの設定を適用中..."
    
    # ディレクトリとファイルの存在確認
    if [[ ! -d "$REPO_ROOT/shell" ]]; then
        handle_error "$REPO_ROOT/shell ディレクトリが見つかりません"
    fi
    
    if [[ ! -f "$REPO_ROOT/shell/.zprofile" ]]; then
        handle_error "$REPO_ROOT/shell/.zprofile ファイルが見つかりません"
    fi
    
    # .zprofileファイルのシンボリックリンクを作成
    create_symlink "$REPO_ROOT/shell/.zprofile" "$HOME/.zprofile"
    log_installed ".zprofile"
    
    # 設定を反映（CI環境ではスキップ）
    if [ "$IS_CI" != "true" ] && [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi
    
    log_success "シェルの設定を適用完了"
}

# MARK: - Verify

# シェル環境を検証する関数
verify_shell_setup() {
    log_start "シェル環境を検証中..."
    local verification_failed=false
    
    # シェルの確認（CI環境はbashを許容）
    current_shell=$(echo $SHELL)
    if [ "$IS_CI" = "true" ]; then
        # CI環境ではbashも許容
        if [[ "$current_shell" == */bash || "$current_shell" == */zsh ]]; then
            log_success "CI環境: シェルがbashまたはzshです: $current_shell"
        else
            log_warning "CI環境: 未知のシェルが使用されています: $current_shell"
        fi
    else
        # 通常環境ではzshのみ
        if [ "$current_shell" != "/bin/zsh" ] && [ "$current_shell" != "/usr/bin/zsh" ] && [ "$current_shell" != "/usr/local/bin/zsh" ]; then
            log_error "シェルがzshに設定されていません: $current_shell"
            verification_failed=true
        else
            log_success "シェルがzshに設定されています: $current_shell"
        fi
    fi
    
    # .zprofileの確認
    if [ ! -f "$HOME/.zprofile" ]; then
        log_error ".zprofileが見つかりません"
        verification_failed=true
    else
        if [ -L "$HOME/.zprofile" ]; then
            ZPROFILE_TARGET=$(readlink "$HOME/.zprofile")
            if [ "$ZPROFILE_TARGET" = "$REPO_ROOT/shell/.zprofile" ]; then
                log_success ".zprofileが正しくシンボリックリンクされています"
            else
                log_error ".zprofileのシンボリックリンク先が異なります"
                log_error "期待: $REPO_ROOT/shell/.zprofile"
                log_error "実際: $ZPROFILE_TARGET"
                verification_failed=true
            fi
        else
            log_warning ".zprofileがシンボリックリンクではありません"
        fi
    fi
    
    # 環境変数の確認（基本的な環境変数が設定されているか）
    if [ -z "$PATH" ]; then
        log_error "PATH環境変数が設定されていません"
        verification_failed=true
    else
        log_success "PATH環境変数が設定されています"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "シェル環境の検証に失敗しました"
        return 1
    else
        log_success "シェル環境の検証が完了しました"
        return 0
    fi
} 