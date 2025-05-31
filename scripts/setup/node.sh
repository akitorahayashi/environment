#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Node.js のセットアップ
setup_node() {
    log_start "Node.js のセットアップを開始します..."

    # Node.js のインストール確認
    if ! command_exists node; then
        log_warning "Node.js がインストールされていません。Brewfileを確認してください。"
        return 1
    fi
    log_installed "Node.js"

    # npm のインストール確認
    if ! command_exists npm; then
        log_warning "npm がインストールされていません。Node.js のインストールを確認してください。"
        return 1
    fi
    log_installed "npm"

    # グローバルパッケージのインストール
    install_global_packages

    log_success "Node.js のセットアップが完了しました"
    return 0
}

# グローバルパッケージのインストール
install_global_packages() {
    local packages_file="$REPO_ROOT/config/node/global-packages.json"
    
    if [ ! -f "$packages_file" ]; then
        log_warning "global-packages.json が見つかりません。グローバルパッケージのインストールをスキップします"
        return 0
    fi
    
    log_info "グローバルパッケージをチェック中..."
    
    # JSONファイルからパッケージリストを読み込む
    local packages=($(jq -r '.packages[]' "$packages_file" 2>/dev/null))
    
    if [ ${#packages[@]} -eq 0 ]; then
        log_warning "global-packages.json にパッケージが定義されていません"
        return 0
    fi
    
    # 各パッケージをインストール
    for package in "${packages[@]}"; do
        if npm list -g "$package" &>/dev/null; then
            log_installed "$package"
        else
            log_installing "$package"
            if npm install -g "$package"; then
                log_success "$package のインストールが完了しました"
            else
                log_error "$package のインストールに失敗しました"
                return 1
            fi
        fi
    done
    
    return 0
}

# Node.js 環境を検証
verify_node_setup() {
    log_start "Node.js 環境を検証中..."
    local verification_failed=false
    
    # Node.js の確認
    if ! command_exists node; then
        log_error "Node.js がインストールされていません"
        verification_failed=true
    else
        log_success "Node.js: $(node --version)"
    fi
    
    # npm の確認
    if ! command_exists npm; then
        log_error "npm がインストールされていません"
        verification_failed=true
    else
        log_success "npm: $(npm --version)"
    fi
    
    # グローバルパッケージの確認
    verify_global_packages || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Node.js 環境の検証に失敗しました"
        return 1
    else
        log_success "Node.js 環境の検証が完了しました"
        return 0
    fi
}

# グローバルパッケージの検証
verify_global_packages() {
    local packages_file="$REPO_ROOT/config/node/global-packages.json"
    
    if [ ! -f "$packages_file" ]; then
        log_warning "global-packages.json が見つかりません"
        return 0
    fi
    
    local packages=($(jq -r '.packages[]' "$packages_file" 2>/dev/null))
    local missing=0
    
    for package in "${packages[@]}"; do
        if ! npm list -g "$package" &>/dev/null; then
            log_error "グローバルパッケージ $package がインストールされていません"
            ((missing++))
        else
            log_success "グローバルパッケージ $package がインストールされています"
        fi
    done
    
    if [ $missing -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# メイン関数
main() {
    log_start "Node.js 環境のセットアップを開始します"
    
    setup_node
    
    log_success "Node.js 環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 