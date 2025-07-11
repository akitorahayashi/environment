#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# インストール実行フラグ
installation_performed=false

# Git の設定を適用
setup_git_config() {
    echo ""
    echo "==== Start: Gitの設定ファイルのセットアップを開始します... ===="

    mkdir -p "$HOME/.config/git"
    local src="$REPO_ROOT/config/git/.gitconfig"
    local dest="$HOME/.config/git/config"

    # Only apply if missing or different
    if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest" ]; then
        if [ -f "$dest" ] || [ -L "$dest" ]; then
            echo "[INFO] 既存の設定ファイルを削除します: $dest"
            rm -f "$dest"
        fi
        echo "[INFO] Gitの設定ファイルをコピーします..."
        if cp "$src" "$dest"; then
            echo "[SUCCESS] Gitの設定ファイルをコピーしました。"
        else
            echo "[ERROR] Gitの設定ファイルのコピーに失敗しました。"
            exit 2
        fi
    else
        echo "[INFO] Gitの設定ファイルは最新です。スキップします。"
    fi
    echo "[SUCCESS] Git の設定適用完了"
    return 0
}

# gitignore_global を設定
setup_gitignore_global() {
    echo ""
    echo "==== Start: gitignore_globalのセットアップを開始します... ===="

    local ignore_file="$HOME/.gitignore_global"

    # 既存ファイルがあれば削除
    if [ -e "$ignore_file" ]; then
        echo "[INFO] 既存の gitignore_global を削除します: $ignore_file"
        rm -f "$ignore_file"
    fi

    # シンボリックリンクの作成
    echo "[INFO] gitignore_global のシンボリックリンクを作成します..."
    if ln -s "$REPO_ROOT/config/git/.gitignore_global" "$ignore_file"; then
        echo "[SUCCESS] gitignore_global のシンボリックリンクを作成しました。"
    else
        echo "[ERROR] gitignore_global のシンボリックリンク作成に失敗しました。"
        exit 2
    fi

    # Git に global gitignore を設定
    echo "[INFO] Git の core.excludesfile を更新しています..."
    git config --global core.excludesfile "$ignore_file"
    echo "[SUCCESS] Git の core.excludesfile に global gitignore を設定しました。"

    echo "[SUCCESS] gitignore_global の設定完了"
    return 0
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    echo ""
    echo "==== Start: SSH エージェントとキーの確認中... ===="
    
    # SSH キーが存在するかチェック
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "[SUCCESS] SSH キー (id_ed25519) が存在します"
        
        # SSH エージェントを起動
        eval "$(ssh-agent -s)"
        
        # SSH キーをエージェントに追加
        echo "[INFO] SSH キーを SSH エージェントに追加中..."
        if ssh-add "$HOME/.ssh/id_ed25519"; then
            echo "[SUCCESS] SSH キーが正常に追加されました"
        else
            echo "[WARN] SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
        fi
    else
        echo "[WARN] SSH キー (id_ed25519) が見つかりません"
        echo "[INFO] 手動でSSHキーを生成してください："
        echo "[INFO] ssh-keygen -t ed25519 -C \"your_email@example.com\""
    fi
}

# Gitの環境を検証
verify_git_setup() {
    echo ""
    echo "==== Start: Git設定を検証中... ===="
    local verification_failed=false

    # 各要素の検証
    verify_git_command || return 1 # Gitコマンド自体の検証は必要

    # 設定ファイルの存在確認
    if [ ! -f "$HOME/.config/git/config" ]; then
        echo "[ERROR] $HOME/.config/git/config が存在しません。"
        verification_failed=true
    else
        echo "[SUCCESS] $HOME/.config/git/config が存在します。"
    fi

    # SSHキーの検証
    verify_ssh_keys || verification_failed=true
    verify_gitignore_global || verification_failed=true

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Git環境の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] Git環境の検証が完了しました"
        return 0
    fi
}

# gitignore_global の検証
verify_gitignore_global() {
    local ignore_file="$HOME/.gitignore_global"
    if [ ! -L "$ignore_file" ]; then
        echo "[ERROR] $ignore_file がシンボリックリンクではありません。"
        return 1
    fi

    local link_target
    link_target=$(readlink "$ignore_file")
    local expected_target="$REPO_ROOT/config/git/.gitignore_global"

    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] $ignore_file が期待される場所を指しています"
    else
        echo "[WARN] $ignore_file は期待されない場所を指しています: $link_target"
        return 1
    fi

    local config_value
    config_value=$(git config --global core.excludesfile 2>/dev/null)
    if [ "$config_value" = "$ignore_file" ]; then
        echo "[SUCCESS] Git の core.excludesfile が正しく設定されています"
        return 0
    else
        echo "[ERROR] Git の core.excludesfile が $config_value になっています"
        return 1
    fi
}

# Gitコマンドの検証
verify_git_command() {
    if ! command -v git; then
        echo "[ERROR] "gitコマンドが見つかりません""
        return 1
    fi
    echo "[SUCCESS] "gitコマンドが使用可能です: $(git --version)""
    return 0
}

# SSHキーの検証
verify_ssh_keys() {
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo "[SUCCESS] SSH鍵ファイル(id_ed25519)が存在します"
        return 0
    else
        # CI環境ではキーが存在しない場合もあるため警告に留める
        if [ "$IS_CI" = "true" ]; then
             echo "[WARN] [CI] SSH鍵ファイル(id_ed25519)が見つかりません"
             return 0 # CIではエラーにしない
        else
             echo "[ERROR] SSH鍵ファイル(id_ed25519)が見つかりません"
             return 1
        fi
    fi
}

# メイン関数
main() {
    echo "==== Start: "Git環境のセットアップを開始します""
    
    setup_git_config
    setup_gitignore_global
    setup_ssh_agent
    
    echo "[SUCCESS] "Git環境のセットアップが完了しました""
    
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