#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    echo "[Start] シェル設定ファイルのセットアップを開始します..."

    # シンボリックリンクの作成
    echo "[INFO] シェル設定ファイルのシンボリックリンクを作成します..."
    if ln -sf "$REPO_ROOT/config/shell/.zprofile" "$HOME/.zprofile"; then
        echo "[SUCCESS] .zprofile のシンボリックリンクを作成しました。"
    else
        echo "[ERROR] .zprofile のシンボリックリンク作成に失敗しました。"
        exit 1
    fi
    if ln -sf "$REPO_ROOT/config/shell/.zshrc" "$HOME/.zshrc"; then
        echo "[SUCCESS] .zshrc のシンボリックリンクを作成しました。"
    else
        echo "[ERROR] .zshrc のシンボリックリンク作成に失敗しました。"
        exit 1
    fi

    echo "[SUCCESS] シェル環境のセットアップが完了しました"

    verify_shell_setup
}

verify_shell_setup() {
    echo "[Start] シェル設定を検証中..."
    local verification_failed=false

    verify_shell_type || verification_failed=true
    verify_zprofile || verification_failed=true
    verify_zshrc || verification_failed=true
    verify_env_vars || verification_failed=true

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] シェル設定の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] シェル設定の検証が正常に完了しました"
        return 0
    fi
}

verify_shell_type() {
    # CI環境ではシェルの種類をチェックしない
    if [ "$IS_CI" = "true" ]; then
        echo "[INFO] CI環境のため、シェルの種類の検証をスキップします。"
        return 0
    fi

    current_shell=$(echo $SHELL)
    # 通常環境ではzshのみ
    if [[ "$current_shell" == */zsh ]]; then
        echo "[SUCCESS] シェルがzshに設定されています: $current_shell"
        return 0
    else
        echo "[ERROR] シェルがzshに設定されていません: $current_shell"
        return 1
    fi
}

verify_zprofile() {
    if [ ! -L "$HOME/.zprofile" ]; then
        echo "[ERROR] .zprofile がシンボリックリンクではありません"
        return 1
    fi

    local link_target
    link_target=$(readlink "$HOME/.zprofile")
    local expected_target="$REPO_ROOT/config/shell/.zprofile"

    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] .zprofile がシンボリックリンクとして存在し、期待される場所を指しています"
        return 0
    else
        echo "[WARN] .zprofile はシンボリックリンクですが、期待しない場所を指しています:"
        echo "[WARN]   期待: $expected_target"
        echo "[WARN]   実際: $link_target"
        return 1
    fi
}

verify_zshrc() {
    if [ ! -L "$HOME/.zshrc" ]; then
        echo "[ERROR] .zshrc がシンボリックリンクではありません"
        return 1
    fi

    local link_target
    link_target=$(readlink "$HOME/.zshrc")
    local expected_target="$REPO_ROOT/config/shell/.zshrc"

    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] .zshrc がシンボリックリンクとして存在し、期待される場所を指しています"
        return 0
    else
        echo "[WARN] .zshrc はシンボリックリンクですが、期待しない場所を指しています:"
        echo "[WARN]   期待: $expected_target"
        echo "[WARN]   実際: $link_target"
        return 1
    fi
}

verify_env_vars() {
    if [ -z "$PATH" ]; then
        echo "[ERROR] PATH環境変数が設定されていません"
        return 1
    else
        echo "[SUCCESS] PATH環境変数が設定されています"
        return 0
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi