#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Apple Silicon 向け Rosetta 2 のインストール
install_rosetta() {
    # Intel Macの場合は不要
    if [[ "$(uname -m)" != "arm64" ]]; then
        log_success "この Mac は Apple Silicon ではないため、Rosetta 2 は不要"
        return 0
    fi
    
    # Mac のチップモデルを取得
    MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
    log_info "🖥  Mac Model: $MAC_MODEL"

    # すでに Rosetta 2 がインストールされているかチェック
    if pgrep oahd >/dev/null 2>&1; then
        log_installed "Rosetta 2"
        return 0
    fi

    # Rosetta 2 をインストール
    log_installing "Rosetta 2" "Apple Silicon ($MAC_MODEL)"
    
    # CI環境では非対話型でインストール
    softwareupdate --install-rosetta --agree-to-license || {
        if [ "$IS_CI" = "true" ]; then
            log_warning "Rosetta 2 のインストールに問題が発生しましたが、CI環境のため続行します"
            return 0
        else
            handle_error "Rosetta 2 のインストールに失敗しました"
        fi
    }

    # インストールの成否をチェック
    if pgrep oahd >/dev/null 2>&1; then
        log_success "Rosetta 2 のインストールが完了しました"
    else
        handle_error "Rosetta 2 のインストールに失敗しました"
    fi
}

# Mac のシステム設定を適用
setup_mac_settings() {
    log_start "Mac のシステム設定を適用中..."
    
    # 設定ファイルの存在確認
    local settings_file="$REPO_ROOT/scripts/macos/setup_mac_settings.sh"
    if [[ ! -f "$settings_file" ]]; then
        log_warning "setup_mac_settings.sh が見つかりません"
        return 1
    fi
    
    # 設定ファイルの内容を確認
    log_info "📝 Mac 設定ファイルをチェック中..."
    local setting_count=$(grep -v "^#" "$settings_file" | grep -v "^$" | grep -E "defaults write" | wc -l | tr -d ' ')
    log_info "🔍 $setting_count 個の設定項目が検出されました"
    
    # CI環境では適用のみスキップ
    if [ "$IS_CI" = "true" ]; then
        log_info "ℹ️ CI環境では Mac システム設定の適用をスキップします（検証のみ実行）"
        
        # 主要な設定カテゴリを確認
        for category in "Dock" "Finder" "screenshots"; do
            if grep -q "$category" "$settings_file"; then
                log_success "$category に関する設定が含まれています"
            fi
        done
        
        return 0
    fi
    
    # 非CI環境では設定を適用
    if ! source "$settings_file" 2>/dev/null; then
        log_warning "Mac 設定の適用中に一部エラーが発生しましたが、続行します"
    else
        log_success "Mac のシステム設定が適用されました"
    fi
    
    # 設定が正常に適用されたか確認（一部の設定のみ）
    check_settings_applied
    
    return 0
}

# 設定が適用されたかチェック
check_settings_applied() {
    for setting in "com.apple.dock" "com.apple.finder"; do
        if defaults read "$setting" &>/dev/null; then
            log_success "${setting##*.} の設定が正常に適用されました"
        else
            log_warning "${setting##*.} の設定の適用に問題がある可能性があります"
        fi
    done
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
    verify_rosetta_if_needed
    
    # macOS設定の確認
    verify_macos_preferences
    
    # システム整合性の確認
    verify_system_integrity
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Mac環境の検証に失敗しました"
        return 1
    else
        log_success "Mac環境の検証が完了しました"
        return 0
    fi
}

# Rosettaの検証（Apple Siliconの場合のみ）
verify_rosetta_if_needed() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        log_info "Macモデル: $MAC_MODEL"
        
        if pgrep oahd >/dev/null 2>&1; then
            log_success "Rosetta 2が正しく設定されています"
        else
            log_error "Rosetta 2が設定されていません"
            verification_failed=true
        fi
    else
        log_success "Intel Macではないため、Rosetta 2は不要です"
    fi
}

# macOS設定ファイルの検証
verify_macos_preferences() {
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
}

# システム整合性保護の検証
verify_system_integrity() {
    if csrutil status | grep -q "enabled"; then
        log_success "システム整合性保護が有効です"
    else
        log_warning "システム整合性保護が無効になっています"
    fi
}

# メイン関数
main() {
    log_start "macOS環境のセットアップを開始します"
    
    install_rosetta
    setup_mac_settings
    
    log_success "macOS環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 