#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード


# インストール実行フラグ
installation_performed=false

# シェル設定ファイルを適用する
setup_shell_config() {
    echo "==== Start: "シェル設定ファイルのセットアップを開始します...""

    # 既存の設定ファイルの削除
    if [ -f "$HOME/.zprofile" ] || [ -L "$HOME/.zprofile" ]; then
        rm -f "$HOME/.zprofile"
    fi
    if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
        rm -f "$HOME/.zshrc"
    fi

    # シンボリックリンクの作成
    echo "[INFO] "シェル設定ファイルのシンボリックリンクを作成します...""
    if ln -s "$REPO_ROOT/config/shell/.zprofile" "$HOME/.zprofile" && \
       ln -s "$REPO_ROOT/config/shell/.zshrc" "$HOME/.zshrc"; then
        echo "[SUCCESS] "シェル設定ファイルのシンボリックリンクを作成しました。""
    else
        echo "[ERROR] "シェル設定ファイルのシンボリックリンク作成に失敗しました。""
        exit 2
    fi

    echo "[SUCCESS] "シェル設定ファイルのセットアップが完了しました。""
    return 0
}

# シェル環境を検証
verify_shell_setup() {
    echo "==== Start: "シェル設定を検証中...""
    local verification_failed=false

    verify_shell_type || verification_failed=true
    verify_zprofile || verification_failed=true
    verify_zshrc || verification_failed=true
    verify_env_vars || verification_failed=true

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] "シェル設定の検証に失敗しました""
        return 1
    else
        echo "[SUCCESS] "シェル設定の検証が正常に完了しました""
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
            echo "[SUCCESS] "CI環境: シェルがbashまたはzshです: $current_shell""
            return 0
        else
            echo "[WARN] "CI環境: 未知のシェルが使用されています: $current_shell""
            return 0
        fi
    else
        # 通常環境ではzshのみ
        if [[ "$current_shell" == */zsh ]]; then
            echo "[SUCCESS] "シェルがzshに設定されています: $current_shell""
            return 0
        else
            echo "[ERROR] "シェルがzshに設定されていません: $current_shell""
            return 1
        fi
    fi
}

# .zprofileの検証
verify_zprofile() {
    if [ ! -L "$HOME/.zprofile" ]; then
        echo "[ERROR] ".zprofile がシンボリックリンクではありません""
        return 1
    fi

    local link_target
    link_target=$(readlink "$HOME/.zprofile")
    local expected_target="$REPO_ROOT/config/shell/.zprofile"

    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] ".zprofile がシンボリックリンクとして存在し、期待される場所を指しています""
        return 0
    else
        echo "[WARN] ".zprofile はシンボリックリンクですが、期待しない場所を指しています:""
        echo "[WARN] "  期待: $expected_target""
        echo "[WARN] "  実際: $link_target""
        return 1
    fi
}

# .zshrcの検証
verify_zshrc() {
    if [ ! -L "$HOME/.zshrc" ]; then
        echo "[ERROR] ".zshrc がシンボリックリンクではありません""
        return 1
    fi

    local link_target
    link_target=$(readlink "$HOME/.zshrc")
    local expected_target="$REPO_ROOT/config/shell/.zshrc"

    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] ".zshrc がシンボリックリンクとして存在し、期待される場所を指しています""
        return 0
    else
        echo "[WARN] ".zshrc はシンボリックリンクですが、期待しない場所を指しています:""
        echo "[WARN] "  期待: $expected_target""
        echo "[WARN] "  実際: $link_target""
        return 1
    fi
}

# 環境変数の検証
verify_env_vars() {
    if [ -z "$PATH" ]; then
        echo "[ERROR] "PATH環境変数が設定されていません""
        return 1
    else
        echo "[SUCCESS] "PATH環境変数が設定されています""
        return 0
    fi
}

# メイン関数
main() {
    echo "==== Start: "シェル環境のセットアップを開始します""
    
    setup_shell_config
    
    echo "[SUCCESS] "シェル環境のセットアップが完了しました""
    
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

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 