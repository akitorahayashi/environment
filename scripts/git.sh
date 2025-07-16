#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    setup_git_config
    setup_gitignore_global
    setup_ssh_agent
    
    echo "[SUCCESS] Git環境のセットアップが完了しました"

    verify_git_setup
}

setup_git_config() {
    echo "[Start] Gitの設定ファイルのセットアップを開始します..."

    mkdir -p "$HOME/.config/git"
    local src="$REPO_ROOT/config/git/.gitconfig"
    local dest="$HOME/.config/git/config"

    # 既存のユーザー設定を保持
    local existing_user_name=""
    local existing_user_email=""
    
    if git config --global user.name >/dev/null 2>&1; then
        existing_user_name=$(git config --global user.name)
        echo "[INFO] 既存のユーザー名を保持します: $existing_user_name"
    fi
    
    if git config --global user.email >/dev/null 2>&1; then
        existing_user_email=$(git config --global user.email)
        echo "[INFO] 既存のメールアドレスを保持します: $existing_user_email"
    fi

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
            exit 1
        fi
    else
        echo "[INFO] Gitの設定ファイルは最新です。スキップします。"
    fi

    # 保持していたユーザー設定を復元
    if [ -n "$existing_user_name" ]; then
        echo "[INFO] ユーザー名を復元します: $existing_user_name"
        git config --global user.name "$existing_user_name"
    fi
    
    if [ -n "$existing_user_email" ]; then
        echo "[INFO] メールアドレスを復元します: $existing_user_email"
        git config --global user.email "$existing_user_email"
    fi
    
    echo "[SUCCESS] Git の設定適用完了"
    return 0
}

setup_gitignore_global() {
    echo ""
    echo "==== Start: gitignore_globalのセットアップを開始します... ===="

    local ignore_file="$HOME/.gitignore_global"

    # シンボリックリンクの作成
    echo "[INFO] gitignore_global のシンボリックリンクを作成します..."
    if ln -sf "$REPO_ROOT/config/git/.gitignore_global" "$ignore_file"; then
        echo "[SUCCESS] gitignore_global のシンボリックリンクを作成しました。"
    else
        echo "[ERROR] gitignore_global のシンボリックリンク作成に失敗しました。"
        exit 1
    fi

    # Git に global gitignore を設定
    echo "[INFO] Git の core.excludesfile を更新しています..."
    git config --global core.excludesfile "$ignore_file"
    echo "[SUCCESS] Git の core.excludesfile に global gitignore を設定しました。"

    echo "[SUCCESS] gitignore_global の設定完了"
    return 0
}

setup_ssh_agent() {
    echo ""
    echo "==== Start: SSH エージェントとキーの確認中... ===="
    
    # SSH キーが存在するかチェック
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "[SUCCESS] SSH キー (id_ed25519) が存在します"
        
        # SSH エージェントが既に動いているかチェック
        if ! ssh-add -l >/dev/null 2>&1; then
            echo "[INFO] SSH エージェントを起動中..."
            eval "$(ssh-agent -s)"
        else
            echo "[INFO] SSH エージェントは既に動作中です"
        fi
        
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

verify_git_setup() {
    echo ""
    echo "==== Start: Git設定を検証中... ===="
    local verification_failed=false

    # git コマンドの検証
    verify_git_command || return 1

    # 設定ファイルの存在確認（setup 関数の後なので必ず存在するはず）
    echo "[SUCCESS] $HOME/.config/git/config が存在します。"

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

verify_git_command() {
    echo "[SUCCESS] gitコマンドが使用可能です: $(git --version)"
    return 0
}

verify_ssh_keys() {
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        echo "[SUCCESS] SSH鍵ファイル(id_ed25519)が存在します"
        return 0
    else
        echo "[WARN] SSH鍵ファイル(id_ed25519)が見つかりません"
        return 0 # 警告のみでエラーにしない
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi