#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Apple Silicon 向け Rosetta 2 のインストール
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Mac のチップモデルを取得
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        log_info " 🖥  Mac Model: $MAC_MODEL"

        # すでに Rosetta 2 がインストールされているかチェック
        if pgrep oahd >/dev/null 2>&1; then
            log_success "Rosetta 2 はすでにインストール済み"
            return
        fi

        # Rosetta 2 をインストール
        log_start "Rosetta 2 を Apple Silicon ($MAC_MODEL) 向けにインストール中..."
        if [ "$IS_CI" = "true" ]; then
            # CI環境では非対話型でインストール
            softwareupdate --install-rosetta --agree-to-license || true
        else
            softwareupdate --install-rosetta --agree-to-license
        fi

        # インストールの成否をチェック
        if pgrep oahd >/dev/null 2>&1; then
            log_success "Rosetta 2 のインストールが完了しました"
        else
            handle_error "Rosetta 2 のインストールに失敗しました"
        fi
    else
        log_success "この Mac は Apple Silicon ではないため、Rosetta 2 は不要"
    fi
}

# Mac のシステム設定を適用
setup_mac_settings() {
    log_start "Mac のシステム設定を適用中..."
    
    # 設定ファイルの存在確認
    if [[ ! -f "$REPO_ROOT/macos/setup_mac_settings.sh" ]]; then
        log_warning "setup_mac_settings.sh が見つかりません"
        return 1
    fi
    
    # 設定ファイルの内容を確認
    log_info "📝 Mac 設定ファイルをチェック中..."
    local setting_count=$(grep -v "^#" "$REPO_ROOT/macos/setup_mac_settings.sh" | grep -v "^$" | grep -E "defaults write" | wc -l | tr -d ' ')
    log_info "🔍 $setting_count 個の設定項目が検出されました"
    
    # CI環境では適用のみスキップ
    if [ "$IS_CI" = "true" ]; then
        log_info "ℹ️ CI環境では Mac システム設定の適用をスキップします（検証のみ実行）"
        
        # 主要な設定カテゴリを確認
        for category in "Dock" "Finder" "screenshots"; do
            if grep -q "$category" "$REPO_ROOT/macos/setup_mac_settings.sh"; then
                log_success "$category に関する設定が含まれています"
            fi
        done
        
        return 0
    fi
    
    # 非CI環境では設定を適用
    # エラーがあっても続行し、完全に失敗した場合のみエラー表示
    if ! source "$REPO_ROOT/macos/setup_mac_settings.sh" 2>/dev/null; then
        log_warning "Mac 設定の適用中に一部エラーが発生しました"
        log_info "エラーを無視して続行します"
    else
        log_success "Mac のシステム設定が適用されました"
    fi
    
    # 設定が正常に適用されたか確認（一部の設定のみ）
    for setting in "com.apple.dock" "com.apple.finder"; do
        if defaults read "$setting" &>/dev/null; then
            log_success "${setting##*.} の設定が正常に適用されました"
        else
            log_warning "${setting##*.} の設定の適用に問題がある可能性があります"
        fi
    done
    
    return 0
}

# Mac環境を検証する関数
verify_mac_setup() {
    log_start "Mac環境を検証中..."
    local verification_failed=false
    
    # macOSバージョンの確認
    OS_VERSION=$(sw_vers -productVersion)
    if [ -z "$OS_VERSION" ]; then
        log_error "macOSバージョンを取得できません"
        verification_failed=true
    else
        log_success "macOSバージョン: $OS_VERSION"
    fi
    
    # Arm64アーキテクチャの場合はRosetta 2を確認
    if [[ "$(uname -m)" == "arm64" ]]; then
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        log_info "Macモデル: $MAC_MODEL"
        
        # Apple Siliconの場合、Rosetta 2の確認
        # Rosetta 2の確認
        if pgrep oahd >/dev/null 2>&1; then
            log_success "Rosetta 2が正しく設定されています"
        else
            log_error "Rosetta 2が設定されていません"
            verification_failed=true
        fi
    else
        log_success "Intel Macではないため、Rosetta 2は不要です"
    fi
    
    # macOS設定の確認
    if [ -f "$HOME/Library/Preferences/com.apple.finder.plist" ]; then
        log_success "Finder設定ファイルが存在します"
    else
        log_warning "Finder設定ファイルが見つかりません"
    fi
    
    if [ -f "$HOME/Library/Preferences/com.apple.dock.plist" ]; then
        log_success "Dock設定ファイルが存在します"
    else
        log_warning "Dock設定ファイルが見つかりません"
    fi
    
    # システム整合性の確認
    if csrutil status | grep -q "enabled"; then
        log_success "システム整合性保護が有効です"
    else
        log_warning "システム整合性保護が無効になっています"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Mac環境の検証に失敗しました"
        return 1
    else
        log_success "Mac環境の検証が完了しました"
        return 0
    fi
} 