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
}

# MARK: - Verify

# Homebrewのインストールを検証する関数
verify_homebrew_setup() {
    log_start "Homebrewの環境を検証中..."
    local verification_failed=false
    
    # brewコマンドの確認
    if ! command_exists brew; then
        log_error "brewコマンドが見つかりません"
        return 1
    fi
    log_success "brewコマンドが正常に使用可能です"
    
    # バージョン確認（簡易版に変更してBroken pipe回避）
    if [ "$IS_CI" = "true" ]; then
        # CI環境では最小限の出力のみ取得
        BREW_VERSION=$(brew --version | head -n 1 2>/dev/null || echo "不明")
        if [ "$BREW_VERSION" = "不明" ]; then
            log_warning "Homebrewのバージョン取得に問題が発生しましたが続行します"
        else
            log_success "Homebrewのバージョン: $BREW_VERSION"
        fi
    else
        # 通常環境では完全なバージョン情報
        if ! brew --version > /dev/null; then
            log_error "Homebrewのバージョン確認に失敗しました"
            verification_failed=true
        else
            log_success "Homebrewのバージョン: $(brew --version | head -n 1)"
        fi
    fi
    
    # brewバイナリパスの確認
    BREW_PATH=$(which brew)
    if [[ "$(uname -m)" == "arm64" ]] && [[ "$BREW_PATH" != "/opt/homebrew/bin/brew" ]]; then
        log_error "Homebrewのパスが想定と異なります（ARM Mac）"
        log_error "期待: /opt/homebrew/bin/brew"
        log_error "実際: $BREW_PATH"
        verification_failed=true
    elif [[ "$(uname -m)" != "arm64" ]] && [[ "$BREW_PATH" != "/usr/local/bin/brew" ]]; then
        log_error "Homebrewのパスが想定と異なります（Intel Mac）"
        log_error "期待: /usr/local/bin/brew"
        log_error "実際: $BREW_PATH"
        verification_failed=true
    else
        log_success "Homebrewのパスが正しく設定されています: $BREW_PATH"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Homebrewの検証に失敗しました"
        return 1
    else
        log_success "Homebrewの検証が完了しました"
        return 0
    fi
}

# Brewfileに記載されたパッケージが正しくインストールされているか検証する関数
verify_brewfile_installation() {
    log_start "Brewfileのパッケージを検証中..."
    local brewfile_path="${1:-$REPO_ROOT/config/Brewfile}"
    local verification_failed=false
    local missing_packages=0
    
    # Brewfileの存在確認
    if [ ! -f "$brewfile_path" ]; then
        log_error "Brewfileが見つかりません: $brewfile_path"
        return 1
    fi
    log_success "Brewfileが存在します: $brewfile_path"
    
    # Brewfileに記載されたパッケージの総数を確認
    TOTAL_PACKAGES=$(grep -v "^#" "$brewfile_path" | grep -v "^$" | grep -c "brew\|cask" || echo "0")
    log_info "Brewfileに記載されたパッケージ数: $TOTAL_PACKAGES"
    
    # インストールされているパッケージを確認
    INSTALLED_FORMULAE=$(brew list --formula | wc -l | tr -d ' ')
    INSTALLED_CASKS=$(brew list --cask | wc -l | tr -d ' ')
    TOTAL_INSTALLED=$((INSTALLED_FORMULAE + INSTALLED_CASKS))
    
    log_info "インストールされたパッケージ数: $TOTAL_INSTALLED (formulae: $INSTALLED_FORMULAE, casks: $INSTALLED_CASKS)"
    
    # 個別パッケージの確認
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        # brew または cask の行を抽出
        if [[ $line =~ ^brew\ \"([^\"]*)\" ]]; then
            package="${BASH_REMATCH[1]}"
            
            if ! brew list --formula "$package" &>/dev/null; then
                log_error "formula $package がインストールされていません"
                ((missing_packages++))
            else
                log_success "formula $package がインストールされています"
            fi
        elif [[ $line =~ ^cask\ \"([^\"]*)\" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew list --cask "$package" &>/dev/null; then
                log_error "cask $package がインストールされていません"
                ((missing_packages++))
            else
                log_success "cask $package がインストールされています"
            fi
        fi
    done < "$brewfile_path"
    
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