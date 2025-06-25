#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Git の設定を適用
setup_git_config() {
    log_start "Gitの設定ファイルのセットアップを開始します..."

    # ~/.config/gitディレクトリの作成
    mkdir -p "$HOME/.config/git"

    # 既存の設定ファイルの削除
    if [ -f "$HOME/.config/git/config" ] || [ -L "$HOME/.config/git/config" ]; then
        log_info "既存の設定ファイルを削除します: $HOME/.config/git/config"
        rm -f "$HOME/.config/git/config"
    fi

    # 設定ファイルのコピー
    log_info "Gitの設定ファイルをコピーします..."
    if cp "$REPO_ROOT/config/git/.gitconfig" "$HOME/.config/git/config"; then
        log_success "Gitの設定ファイルのコピーを作成しました。"
    else
        log_error "Gitの設定ファイルのコピー作成に失敗しました。"
        return 1
    fi

    log_success "Git の設定適用完了"
    return 0
}

# グローバルGitignoreを設定
setup_gitignore_global() {
    log_start "グローバルgitignoreのセットアップを開始します..."

    local ignore_file="$HOME/.gitignore_global"

    # 既存ファイルがあれば削除
    if [ -e "$ignore_file" ]; then
        log_info "既存のグローバルgitignoreを削除します: $ignore_file"
        rm -f "$ignore_file"
    fi

    # シンボリックリンクの作成
    log_info "グローバルgitignoreのシンボリックリンクを作成します..."
    if ln -s "$REPO_ROOT/config/git/.gitignore_global" "$ignore_file"; then
        log_success "グローバルgitignoreのシンボリックリンクを作成しました。"
    else
        log_error "グローバルgitignoreのシンボリックリンク作成に失敗しました。"
        return 1
    fi

    # Git に global gitignore を設定
    log_info "Git の core.excludesfile を更新しています..."
    git config --global core.excludesfile "$ignore_file"
    log_success "Git の core.excludesfile に global gitignore を設定しました。"

    log_success "グローバルgitignoreの設定完了"
    return 0
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    log_start "SSH エージェントとキーの確認中..."
    
    # SSH キーが存在するかチェック
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        log_success "SSH キー (id_ed25519) が存在します"
        
        # SSH エージェントを起動
        eval "$(ssh-agent -s)"
        
        # SSH キーをエージェントに追加
        log_info "SSH キーを SSH エージェントに追加中..."
        if ssh-add "$HOME/.ssh/id_ed25519"; then
            log_success "SSH キーが正常に追加されました"
        else
            log_warning "SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
        fi
    else
        log_warning "SSH キー (id_ed25519) が見つかりません"
        log_info "手動でSSHキーを生成してください："
        log_info "ssh-keygen -t ed25519 -C \"your_email@example.com\""
    fi
}

# GitHub CLI のインストール
setup_github_cli() {
    # インストール確認
    if ! command_exists gh; then
        log_installing "GitHub CLI"
        brew install gh
        log_success "GitHub CLI のインストール完了"
    else
        log_success "GitHub CLI はすでにインストールされています"
    fi
}

# Git環境を検証
verify_git_setup() {
    log_start "Git設定を検証中..."
    local verification_failed=false

    # 各要素の検証
    verify_git_command || return 1 # Gitコマンド自体の検証は必要

    # 設定ファイルの存在確認
    if [ ! -f "$HOME/.config/git/config" ]; then
        log_error "$HOME/.config/git/config が存在しません。"
        verification_failed=true
    else
        log_success "$HOME/.config/git/config が存在します。"
    fi

    # SSHキーの検証
    verify_ssh_keys || verification_failed=true
    verify_gitignore_global || verification_failed=true

    if [ "$verification_failed" = "true" ]; then
        log_error "Git環境の検証に失敗しました"
        return 1
    else
        log_success "Git環境の検証が完了しました"
        return 0
    fi
}

# グローバルGitignoreの検証
verify_gitignore_global() {
    local ignore_file="$HOME/.gitignore_global"
    if [ ! -L "$ignore_file" ]; then
        log_error "$ignore_file がシンボリックリンクではありません。"
        return 1
    fi

    local link_target
    link_target=$(readlink "$ignore_file")
    local expected_target="$REPO_ROOT/config/git/.gitignore_global"

    if [ "$link_target" = "$expected_target" ]; then
        log_success "$ignore_file が期待される場所を指しています"
    else
        log_warning "$ignore_file は期待されない場所を指しています: $link_target"
        return 1
    fi

    local config_value
    config_value=$(git config --global core.excludesfile 2>/dev/null)
    if [ "$config_value" = "$ignore_file" ]; then
        log_success "Git の core.excludesfile が正しく設定されています"
        return 0
    else
        log_error "Git の core.excludesfile が $config_value になっています"
        return 1
    fi
}

# Gitコマンドの検証
verify_git_command() {
    if ! command_exists git; then
        log_error "gitコマンドが見つかりません"
        return 1
    fi
    log_success "gitコマンドが使用可能です: $(git --version)"
    return 0
}

# SSHキーの検証
verify_ssh_keys() {
    if [ -f "$HOME/.ssh/id_ed25519" ]; then
        log_success "SSH鍵ファイル(id_ed25519)が存在します"
        return 0
    else
        # CI環境ではキーが存在しない場合もあるため警告に留める
        if [ "$IS_CI" = "true" ]; then
             log_warning "[CI] SSH鍵ファイル(id_ed25519)が見つかりません"
             return 0 # CIではエラーにしない
        else
             log_error "SSH鍵ファイル(id_ed25519)が見つかりません"
             return 1
        fi
    fi
}

# メイン関数
main() {
    log_start "Git環境のセットアップを開始します"
    
    setup_git_config
    setup_gitignore_global
    setup_github_cli
    
    log_success "Git環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 