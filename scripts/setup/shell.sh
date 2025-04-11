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

# シェル環境を検証
verify_shell_setup() {
    log_start "シェル環境を検証中..."
    local verification_failed=false
    
    verify_shell_type || verification_failed=true
    verify_zprofile || verification_failed=true
    verify_env_vars || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        log_error "シェル環境の検証に失敗しました"
        return 1
    else
        log_success "シェル環境の検証が完了しました"
        return 0
    fi
}

# シェルタイプの検証
verify_shell_type() {
    current_shell=$(echo $SHELL)
    
    # CI環境とそれ以外で検証条件を分岐
    if [ "$IS_CI" = "true" ]; then
        # CI環境ではbashも許容
        if [[ "$current_shell" == */bash || "$current_shell" == */zsh ]]; then
            log_success "CI環境: シェルがbashまたはzshです: $current_shell"
            return 0
        else
            log_warning "CI環境: 未知のシェルが使用されています: $current_shell"
            return 1
        fi
    else
        # 通常環境ではzshのみ
        if [[ "$current_shell" == */zsh ]]; then
            log_success "シェルがzshに設定されています: $current_shell"
            return 0
        else
            log_error "シェルがzshに設定されていません: $current_shell"
            return 1
        fi
    fi
}

# .zprofileの検証
verify_zprofile() {
    if [ ! -f "$HOME/.zprofile" ]; then
        log_error ".zprofileが見つかりません"
        return 1
    fi
    
    if [ -L "$HOME/.zprofile" ]; then
        ZPROFILE_TARGET=$(readlink "$HOME/.zprofile")
        if [ "$ZPROFILE_TARGET" = "$REPO_ROOT/shell/.zprofile" ]; then
            log_success ".zprofileが正しくシンボリックリンクされています"
            return 0
        else
            log_error ".zprofileのシンボリックリンク先が異なります"
            log_error "期待: $REPO_ROOT/shell/.zprofile"
            log_error "実際: $ZPROFILE_TARGET"
            return 1
        fi
    else
        log_warning ".zprofileがシンボリックリンクではありません"
        return 1
    fi
}

# 環境変数の検証
verify_env_vars() {
    if [ -z "$PATH" ]; then
        log_error "PATH環境変数が設定されていません"
        return 1
    else
        log_success "PATH環境変数が設定されています"
        return 0
    fi
} 