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
    
    # SSH キーが存在するか確認し、なければ作成
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_info "SSH キーが見つかりません。新しく生成します..."
        
        # .gitconfigからメールアドレスを取得
        local git_email=$(git config --get user.email)
        if [ -z "$git_email" ]; then
            log_warning ".gitconfigにメールアドレスが設定されていません"
            git_email="your_email@example.com"
        fi
        
        if [ "$IS_CI" = "true" ]; then
            log_info "CI環境では対話型のSSHキー生成をスキップします"
            # CI環境では非対話型でキーを生成（実際のメールアドレスは使用しない）
            ssh-keygen -t ed25519 -C "ci-test@example.com" -f "$HOME/.ssh/id_ed25519" -N "" -q
        else
            ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
        fi
        log_success "SSH キーの生成が完了しました"
    fi

    # SSH キーをエージェントに追加
    log_info "SSH キーを SSH エージェントに追加中..."
    if ssh-add "$HOME/.ssh/id_ed25519"; then
        log_success "SSH キーが正常に追加されました"
    else
        log_warning "SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
    fi
}

# GitHub CLI のインストールと認証
setup_github_cli() {
    if ! command_exists gh; then
        log_start "GitHub CLI をインストール中..."
        brew install gh
        log_success "GitHub CLI のインストール完了"
    else
        log_success "GitHub CLI はすでにインストールされています"
    fi

    # 待機メッセージを表示
    echo "⏳ GitHub CLIの認証確認中..."

    # 認証状態をチェック
    if ! gh auth status &>/dev/null; then
        log_info "GitHub CLI の認証が必要です"
        
        # CI環境での処理
        if [ "$IS_CI" = "true" ]; then
            if [ -n "$GITHUB_TOKEN_CI" ]; then
                log_info "CI環境用のGitHubトークンを使用して認証を行います"
                echo "$GITHUB_TOKEN_CI" | gh auth login --with-token
                if [ $? -eq 0 ]; then
                    log_success "CI環境でのGitHub認証が完了しました"
                else
                    log_warning "CI環境でのGitHub認証に失敗しました"
                fi
            else
                log_info "CI環境ではトークンがないため、認証はスキップします"
            fi
            return 0
        fi
        
        # ユーザーに認証をスキップするか尋ねる
        local skip_auth=""
        read -p "GitHub CLI の認証をスキップしますか？ (y/N): " skip_auth
        
        if [[ "$skip_auth" =~ ^[Yy]$ ]]; then
            log_info "GitHub CLI の認証をスキップします"
            log_warning "後で必要に応じて 'gh auth login' を実行してください（README参照）"
            return 0
        else
            log_info "GitHub CLI の認証を行います..."
            gh auth login || log_warning "GitHub認証に失敗しました。後で手動で認証してください。"
        fi
    else
        log_success "GitHub CLI はすでに認証済みです"
    fi
} 