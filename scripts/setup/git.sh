#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Git の設定を適用
setup_git_config() {
    log_start "Git設定ファイルのセットアップを開始します (stow)..."

    # CI環境でもstowを実行する前に既存ファイルを削除
    if [ -f "$HOME/.gitconfig" ] && [ ! -L "$HOME/.gitconfig" ]; then
        log_warning "既存の .gitconfig ファイルを削除します: $HOME/.gitconfig"
        rm -f "$HOME/.gitconfig"
    fi
    # .gitignore_globalも同様に削除
    if [ -f "$HOME/.gitignore_global" ] && [ ! -L "$HOME/.gitignore_global" ]; then
        log_warning "既存の .gitignore_global ファイルを削除します: $HOME/.gitignore_global"
        rm -f "$HOME/.gitignore_global"
    fi

    local stow_config_dir="$REPO_ROOT/config"
    local stow_package="git"

    # stow コマンドでシンボリックリンクを作成/更新
    log_info "'$stow_package' パッケージを '$stow_config_dir' から '$HOME' にstowします..."
    if stow --dir="$stow_config_dir" --target="$HOME" --restow "$stow_package"; then
        log_success "Git設定ファイルのシンボリックリンクを作成/更新しました。"
    else
        log_error "Git設定ファイルのシンボリックリンク作成/更新に失敗しました。"
        # stowがない場合のエラーはここで捕捉される
        return 1
    fi

    # .gitconfig内の core.excludesfile のパスを設定 (stowの後で実行)
    log_info "Gitのexcludesfileを設定します..."
    if [ -f "$HOME/.gitconfig" ]; then
        if git config --global core.excludesfile "$HOME/.gitignore_global"; then
             log_success "Gitのexcludesfileを設定しました: $HOME/.gitignore_global"
        else
             log_error "Gitのexcludesfileの設定に失敗しました。"
             # 必要に応じて return 1 するか検討
        fi
    else
        log_warning ".gitconfigが見つからないため、excludesfileの設定をスキップします。"
    fi
    log_success "Git の設定適用完了" # stow成功とexcludesfile設定後に完了
    return 0
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    log_start "SSH エージェントをセットアップ中..."
    
    # SSH エージェントを起動
    eval "$(ssh-agent -s)"
    
    # SSHキーの確認と生成
    setup_ssh_keys
    
    # SSH キーをエージェントに追加
    log_info "SSH キーを SSH エージェントに追加中..."
    if ssh-add "$HOME/.ssh/id_ed25519"; then
        log_success "SSH キーが正常に追加されました"
    else
        log_warning "SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
    fi
}

# SSHキーの確認と生成
setup_ssh_keys() {
    if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
        log_installed "SSH キー (id_ed25519)"
        return 0
    fi
    
    log_info "SSH キーが見つかりません。新しく生成します..."
    
    # .gitconfigからメールアドレスを取得
    local git_email=$(git config --get user.email)
    if [ -z "$git_email" ]; then
        log_warning ".gitconfigにメールアドレスが設定されていません"
        git_email="your_email@example.com"
    fi
    
    # 環境に応じてキー生成方法を分岐
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境では対話型のSSHキー生成をスキップします"
        # 非対話型でキーを生成
        ssh-keygen -t ed25519 -C "ci-test@example.com" \
                  -f "$HOME/.ssh/id_ed25519" -N "" -q
    else
        ssh-keygen -t ed25519 -C "$git_email" \
                  -f "$HOME/.ssh/id_ed25519" -N ""
    fi
    
    log_success "SSH キーの生成が完了しました"
}

# GitHub CLI のインストールと認証
setup_github_cli() {
    # インストール確認
    if ! command_exists gh; then
        log_installing "GitHub CLI"
        brew install gh
        log_success "GitHub CLI のインストール完了"
    else
        log_success "GitHub CLI はすでにインストールされています"
    fi

    # 認証設定
    setup_github_auth
}

# GitHub認証設定
setup_github_auth() {
    echo "⏳ GitHub CLIの認証確認中..."

    # 認証済みの場合はスキップ
    if gh auth status &>/dev/null; then
        log_success "GitHub CLI はすでに認証済みです"
        return 0
    fi
    
    log_info "GitHub CLI の認証が必要です"
    
    # CI環境での処理
    if [ "$IS_CI" = "true" ]; then
        setup_github_auth_ci
        return $?
    fi
    
    # 通常環境での処理
    setup_github_auth_interactive
}

# CI環境でのGitHub認証
setup_github_auth_ci() {
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        log_info "CI環境用のGitHubトークンを使用して認証を行います"
        if echo "$GITHUB_TOKEN_CI" | gh auth login --with-token; then
            log_success "CI環境でのGitHub認証が完了しました"
            return 0
        else
            log_warning "CI環境でのGitHub認証に失敗しました"
            return 1
        fi
    else
        log_info "CI環境ではトークンがないため、認証はスキップします"
        return 0
    fi
}

# 対話的なGitHub認証
setup_github_auth_interactive() {
    # ユーザーに認証をスキップするか尋ねる
    local skip_auth=""
    read -p "GitHub CLI の認証をスキップしますか？ (y/N): " skip_auth
    
    if [[ "$skip_auth" =~ ^[Yy]$ ]]; then
        log_info "GitHub CLI の認証をスキップします"
        log_warning "後で必要に応じて 'gh auth login' を実行してください（README参照）"
        return 0
    else
        log_info "GitHub CLI の認証を行います..."
        if gh auth login; then
            log_success "GitHub認証が完了しました"
            return 0
        else
            log_warning "GitHub認証に失敗しました。後で手動で認証してください。"
            return 1
        fi
    fi
}

# Git環境を検証
verify_git_setup() {
    log_start "Git設定を検証中..."
    local verification_failed=false

    # 各要素の検証
    verify_git_command || return 1 # Gitコマンド自体の検証は必要

    # 設定ファイルの存在確認 (stowが成功したかの簡易チェック)
    if [ ! -L "$HOME/.gitconfig" ]; then
        log_error "$HOME/.gitconfig がシンボリックリンクではありません。"
        verification_failed=true
    else
        log_success "$HOME/.gitconfig がシンボリックリンクとして存在します。"
    fi
    if [ ! -L "$HOME/.gitignore_global" ]; then
        log_error "$HOME/.gitignore_global がシンボリックリンクではありません。"
        verification_failed=true
    else
        log_success "$HOME/.gitignore_global がシンボリックリンクとして存在します。"
    fi

    # excludesfileの設定検証は引き続き重要
    verify_git_excludes_config || verification_failed=true

    # SSHキーの検証
    verify_ssh_keys || verification_failed=true # SSHキー検証もそのまま

    if [ "$verification_failed" = "true" ]; then
        log_error "Git環境の検証に失敗しました"
        return 1
    else
        log_success "Git環境の検証が完了しました"
        return 0
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

# excludesfileの設定検証
verify_git_excludes_config() {
    local exclude_file=$(git config --global core.excludesfile)
    local expected_file="$HOME/.gitignore_global"

    if [ -z "$exclude_file" ]; then
        # stow直後だと .gitconfig が反映されていない可能性があるので少し待つ
        sleep 1
        exclude_file=$(git config --global core.excludesfile)
        if [ -z "$exclude_file" ]; then
            log_error "gitのexcludesfileが設定されていません"
            return 1
        fi
    fi

    if [ "$exclude_file" != "$expected_file" ]; then
        log_error "gitのexcludesfileの設定が異なります"
        log_error "期待: $expected_file"
        log_error "実際: $exclude_file"
        return 1
    else
        log_success "gitのexcludesfileが正しく設定されています"
        return 0
    fi
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
    setup_ssh_agent
    setup_github_cli
    
    log_success "Git環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 