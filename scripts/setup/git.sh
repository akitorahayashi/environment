#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Git の設定を適用
setup_git_config() {
    log_start "Git の設定を適用中..."
    
    # シンボリックリンクを作成
    create_symlink "$REPO_ROOT/git/.gitconfig" "$HOME/.gitconfig"
    create_symlink "$REPO_ROOT/git/.gitignore_global" "$HOME/.gitignore_global"
    
    git config --global core.excludesfile "$HOME/.gitignore_global"
    log_success "Git の設定を適用完了"
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
    log_start "Git環境を検証中..."
    local verification_failed=false
    
    # 各要素の検証
    verify_git_command || return 1
    verify_git_config_files || verification_failed=true
    verify_git_excludes_config || verification_failed=true
    verify_ssh_keys
    
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

# Git設定ファイルの検証
verify_git_config_files() {
    local result=0
    
    # .gitconfigの検証
    if ! verify_git_symlink ".gitconfig" "$REPO_ROOT/git/.gitconfig"; then
        result=1
    fi
    
    # .gitignore_globalの検証
    if ! verify_git_symlink ".gitignore_global" "$REPO_ROOT/git/.gitignore_global"; then
        result=1
    fi
    
    return $result
}

# Gitシンボリックリンクの検証
verify_git_symlink() {
    local file_name="$1"
    local expected_target="$2"
    local file_path="$HOME/$file_name"
    
    if [ ! -f "$file_path" ]; then
        log_error "$file_nameが存在しません"
        return 1
    fi
    
    if [ -L "$file_path" ]; then
        local actual_target=$(readlink "$file_path")
        if [ "$actual_target" = "$expected_target" ]; then
            log_success "$file_nameが正しくシンボリックリンクされています"
            return 0
        else
            log_error "$file_nameのシンボリックリンク先が異なります"
            log_error "期待: $expected_target"
            log_error "実際: $actual_target"
            return 1
        fi
    else
        log_warning "$file_nameがシンボリックリンクではありません"
        return 1
    fi
}

# excludesfileの設定検証
verify_git_excludes_config() {
    local exclude_file=$(git config --global core.excludesfile)
    local expected_file="$HOME/.gitignore_global"
    
    if [ -z "$exclude_file" ]; then
        log_error "gitのexcludesfileが設定されていません"
        return 1
    elif [ "$exclude_file" != "$expected_file" ]; then
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
        log_warning "SSH鍵ファイル(id_ed25519)が見つかりません"
        return 1
    fi
} 