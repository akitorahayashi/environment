#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Homebrew のインストール
install_homebrew() {
    if ! command_exists brew; then
        log_start "Homebrew をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            log_info "CI環境では非対話型でインストールします"
            # CI環境では非対話型でインストール
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # インストールの結果を確認
        if ! command_exists brew; then
            handle_error "Homebrewのインストールに失敗しました"
        fi
        
        # Homebrew PATH設定を即時有効化
        if [[ "$(uname -m)" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log_success "Homebrew のインストール完了"
    else
        log_success "Homebrew はすでにインストール済み"
    fi
}

# Brewfile に記載されているパッケージをインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/config/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        handle_error "$brewfile_path が見つかりません"
    fi

    log_start "Homebrew パッケージのインストールを開始します..."

    # GitHub認証の設定 (CI環境用)
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        log_info "🔑 CI環境用のGitHub認証を設定中..."
        # 認証情報を環境変数に設定
        export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN_CI"
        # Gitの認証設定
        git config --global url."https://${GITHUB_ACTOR:-github-actions}:${GITHUB_TOKEN_CI}@github.com/".insteadOf "https://github.com/"
    fi

    # パッケージをインストール
    if ! brew bundle --file "$brewfile_path"; then
        handle_error "Brewfileからのパッケージインストールに失敗しました"
    else
        log_success "Homebrew パッケージのインストールが完了しました"
    fi
    
    # 重要なパッケージが正しくインストールされているか確認
    check_critical_packages
}

# 重要なパッケージの確認
check_critical_packages() {
    log_start "重要なパッケージの確認中..."
    
    CRITICAL_PACKAGES=("flutter" "android-commandlinetools" "temurin")
    for package in "${CRITICAL_PACKAGES[@]}"; do
        if ! brew list --cask "$package" &>/dev/null; then
            handle_error "重要なパッケージ '$package' が見つかりません"
        fi
        log_success "$package が正常にインストールされています"
    done
} 