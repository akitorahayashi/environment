#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Homebrew のインストール
install_homebrew() {
    if ! command_exists brew; then
        log_installing "Homebrew"
        install_homebrew_binary
        setup_homebrew_path
        log_success "Homebrew のインストール完了"
    else
        log_installed "Homebrew"
    fi
}

# Homebrewバイナリのインストール
install_homebrew_binary() {
    local install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境では非対話型でインストールします"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $install_url)"
    else
        /bin/bash -c "$(curl -fsSL $install_url)"
    fi
    
    # インストール結果確認
    if ! command_exists brew; then
        handle_error "Homebrewのインストールに失敗しました"
    fi
}

# Homebrew PATH設定
setup_homebrew_path() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
}

# Brewfile パッケージのインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/brew/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        handle_error "$brewfile_path が見つかりません"
    fi

    log_start "Homebrew パッケージのインストールを開始します..."
    setup_github_auth_for_brew
    install_packages_from_brewfile "$brewfile_path"
}

# GitHub認証設定（CI環境用）
setup_github_auth_for_brew() {
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        log_info "🔑 CI環境用のGitHub認証を設定中..."
        # 認証情報を環境変数に設定
        export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN_CI"
        # Gitの認証設定
        git config --global url."https://${GITHUB_ACTOR:-github-actions}:${GITHUB_TOKEN_CI}@github.com/".insteadOf "https://github.com/"
    fi
}

# Brewfileからパッケージインストール
install_packages_from_brewfile() {
    local brewfile_path="$1"
    
    if ! brew bundle --file "$brewfile_path"; then
        handle_error "Brewfileからのパッケージインストールに失敗しました"
    else
        log_success "Homebrew パッケージのインストールが完了しました"
    fi
}

# Homebrewのインストールを検証
verify_homebrew_setup() {
    log_start "Homebrewの環境を検証中..."
    local verification_failed=false
    
    # brewコマンドの確認
    if ! verify_brew_command; then
        return 1
    fi
    
    # バージョン確認
    verify_brew_version || verification_failed=true
    
    # パス確認
    verify_brew_path || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Homebrewの検証に失敗しました"
        return 1
    else
        log_success "Homebrewの検証が完了しました"
        return 0
    fi
}

# brewコマンドの検証
verify_brew_command() {
    if ! command_exists brew; then
        log_error "brewコマンドが見つかりません"
        return 1
    fi
    log_success "brewコマンドが正常に使用可能です"
    return 0
}

# Homebrewバージョンの検証
verify_brew_version() {
    if [ "$IS_CI" = "true" ]; then
        # CI環境では最小限の出力
        BREW_VERSION=$(brew --version | head -n 1 2>/dev/null || echo "不明")
        if [ "$BREW_VERSION" = "不明" ]; then
            log_warning "Homebrewのバージョン取得に問題が発生しましたが続行します"
            return 0
        else
            log_success "Homebrewのバージョン: $BREW_VERSION"
            return 0
        fi
    else
        # 通常環境での確認
        if ! brew --version > /dev/null; then
            log_error "Homebrewのバージョン確認に失敗しました"
            return 1
        fi
        log_success "Homebrewのバージョン: $(brew --version | head -n 1)"
        return 0
    fi
}

# Homebrewパスの検証
verify_brew_path() {
    BREW_PATH=$(which brew)
    local expected_path=""
    
    # アーキテクチャに応じた期待値
    if [[ "$(uname -m)" == "arm64" ]]; then
        expected_path="/opt/homebrew/bin/brew"
    else
        expected_path="/usr/local/bin/brew"
    fi
    
    if [[ "$BREW_PATH" != "$expected_path" ]]; then
        log_error "Homebrewのパスが想定と異なります"
        log_error "期待: $expected_path"
        log_error "実際: $BREW_PATH"
        return 1
    else
        log_success "Homebrewのパスが正しく設定されています: $BREW_PATH"
        return 0
    fi
}

# Brewfileパッケージの検証
verify_brewfile_installation() {
    log_start "Brewfileのパッケージを検証中..."
    local brewfile_path="${1:-$REPO_ROOT/brew/Brewfile}"
    local verification_failed=false
    
    # Brewfileの存在確認
    if ! verify_brewfile_exists "$brewfile_path"; then
        return 1
    fi
    
    # パッケージ数確認
    verify_package_counts "$brewfile_path"
    
    # 個別パッケージの確認
    local missing_packages=0
    missing_packages=$(verify_individual_packages "$brewfile_path")
    
    if [ $missing_packages -gt 0 ]; then
        log_error "$missing_packages 個のパッケージがインストールされていません"
        verification_failed=true
    else
        log_success "すべてのパッケージが正しくインストールされています"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Brewfileパッケージの検証に失敗しました"
        return 1
    else
        log_success "Brewfileパッケージの検証が完了しました"
        return 0
    fi
}

# Brewfileの存在確認
verify_brewfile_exists() {
    local brewfile_path="$1"
    
    if [ ! -f "$brewfile_path" ]; then
        log_error "Brewfileが見つかりません: $brewfile_path"
        return 1
    fi
    log_success "Brewfileが存在します: $brewfile_path"
    return 0
}

# パッケージ数の確認
verify_package_counts() {
    local brewfile_path="$1"
    
    # Brewfile内のパッケージ数
    local total_defined=$(grep -v "^#" "$brewfile_path" | 
                         grep -v "^$" | 
                         grep -c "brew\|cask" || 
                         echo "0")
    log_info "Brewfileに記載されたパッケージ数: $total_defined"
    
    # インストール済みパッケージ数
    local installed_formulae=$(brew list --formula | wc -l | tr -d ' ')
    local installed_casks=$(brew list --cask | wc -l | tr -d ' ')
    local total_installed=$((installed_formulae + installed_casks))
    
    log_info "インストールされたパッケージ数: $total_installed (formulae: $installed_formulae, casks: $installed_casks)"
}

# 個別パッケージ確認
verify_individual_packages() {
    local brewfile_path="$1"
    local missing=0
    
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        # brew および cask パッケージを抽出・確認
        if [[ $line =~ ^brew\ \"([^\"]*)\" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "formula" || ((missing++))
        elif [[ $line =~ ^cask\ \"([^\"]*)\" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "cask" || ((missing++))
        fi
    done < "$brewfile_path"
    
    echo "$missing"
}

# 個別パッケージの確認
verify_brew_package() {
    local package="$1"
    local type="$2"
    
    if [ "$type" = "formula" ]; then
        if ! brew list --formula "$package" &>/dev/null; then
            log_error "formula $package がインストールされていません"
            return 1
        else
            log_success "formula $package がインストールされています"
            return 0
        fi
    elif [ "$type" = "cask" ]; then
        if ! brew list --cask "$package" &>/dev/null; then
            log_error "cask $package がインストールされていません"
            return 1
        else
            log_success "cask $package がインストールされています"
            return 0
        fi
    fi
}