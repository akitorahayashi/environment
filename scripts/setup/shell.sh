#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# シェル設定ファイルを適用する
setup_shell_config() {
    log_start "シェル設定ファイルのセットアップを開始します..."

    # 既存の設定ファイルの削除
    if [ -f "$HOME/.zprofile" ] || [ -L "$HOME/.zprofile" ]; then
        rm -f "$HOME/.zprofile"
    fi
    if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
    fi

    # シンボリックリンクの作成
    log_info "シェル設定ファイルのシンボリックリンクを作成します..."
    if ln -s "$REPO_ROOT/config/shell/.zprofile" "$HOME/.zprofile" && \
       ln -s "$REPO_ROOT/config/shell/.zshrc" "$HOME/.zshrc"; then
        log_success "シェル設定ファイルのシンボリックリンクを作成しました。"
    else
        log_error "シェル設定ファイルのシンボリックリンク作成に失敗しました。"
        return 1
    fi

    log_success "シェル設定ファイルのセットアップが完了しました。"
    return 0
}

# シェル環境を検証
verify_shell_setup() {
    log_start "シェル設定を検証中..."
    local verification_failed=false

    verify_shell_type || verification_failed=true
    verify_zprofile || verification_failed=true
    verify_env_vars || verification_failed=true

    if [ "$verification_failed" = "true" ]; then
        log_error "シェル設定の検証に失敗しました"
        return 1
    else
        log_success "シェル設定の検証が正常に完了しました"
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
            return 0
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
    if [ ! -L "$HOME/.zprofile" ]; then
        log_error ".zprofile がシンボリックリンクではありません"
        return 1
    fi

    local link_target=$(readlink "$HOME/.zprofile")
    local expected_target="$REPO_ROOT/config/shell/.zprofile"

    if [ "$link_target" = "$expected_target" ]; then
        log_success ".zprofile がシンボリックリンクとして存在し、期待される場所を指しています"
        return 0
    else
        log_warning ".zprofile はシンボリックリンクですが、期待しない場所を指しています:"
        log_warning "  期待: $expected_target"
        log_warning "  実際: $link_target"
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

# メイン関数
main() {
    log_start "シェル環境のセットアップを開始します"
    
    setup_shell_config
    
    log_success "シェル環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 