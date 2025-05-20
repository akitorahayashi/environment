#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# シェル設定ファイルを適用する
setup_shell_config() {
    log_start "シェル設定ファイルのセットアップを開始します (stow)..."
    local stow_config_dir="$REPO_ROOT/config"
    local stow_package="shell"

    # stow コマンドでシンボリックリンクを作成/更新
    log_info "'$stow_package' パッケージを '$stow_config_dir' から '$HOME' にstowします..."
    if stow --dir="$stow_config_dir" --target="$HOME" --restow "$stow_package"; then
        log_success "シェル設定ファイル(.zprofile)のシンボリックリンクを作成/更新しました。"
    else
        log_error "シェル設定ファイルのシンボリックリンク作成/更新に失敗しました。"
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
    verify_zprofile || verification_failed=true # verify_zprofile は残す
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
            # CIではシェルタイプが異なってもエラーとしない場合もあるので警告に留める
            return 0 # return 1 から変更
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

# .zprofileの検証 (stow対応)
verify_zprofile() {
    if [ ! -f "$HOME/.zprofile" ]; then
        log_error ".zprofileが見つかりません"
        return 1
    fi

    if [ -L "$HOME/.zprofile" ]; then
        local link_target=$(readlink "$HOME/.zprofile")
        local expected_target_abs="$REPO_ROOT/config/shell/.zprofile"
        # 相対パスの場合に備えて、リンク元のディレクトリを基準に絶対パスに解決してみる
        local resolved_target_abs
        if [[ "$link_target" != /* ]]; then # リンク先が相対パスの場合
            # readlink -f が使えればそれが一番簡単だが、macOSのデフォルトにはない
            # GNU readlink (brew install coreutils) があれば greadlink -f を使う
            if command -v greadlink &> /dev/null; then
                 resolved_target_abs=$(greadlink -f "$HOME/$link_target")
            else
                 # 自前で解決を試みる (ディレクトリ変更とpwd)
                 # 注意: 複雑な相対パス (`../..` など) ではうまく動かない可能性あり
                 resolved_target_abs="$(cd "$(dirname "$HOME/.zprofile")" && cd "$(dirname "$link_target")" && pwd)/$(basename "$link_target")"
            fi
        else # リンク先が絶対パスの場合
            resolved_target_abs="$link_target"
        fi

        # # デバッグ用ログ
        # log_info "Debug: Link Target Raw: $link_target"
        # log_info "Debug: Expected Target Abs: $expected_target_abs"
        # log_info "Debug: Resolved Target Abs: $resolved_target_abs"

        if [ "$resolved_target_abs" == "$expected_target_abs" ]; then
             log_success ".zprofile がシンボリックリンクとして存在し、期待される場所を指しています"
             return 0
        else
             log_warning ".zprofile はシンボリックリンクですが、期待しない場所を指しています:"
             log_warning "  期待: $expected_target_abs"
             log_warning "  実際 (解決後): $resolved_target_abs (元: $link_target)"
             return 1
        fi
    else
        log_warning ".zprofile がシンボリックリンクではありません。stowによる管理が期待されます。"
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