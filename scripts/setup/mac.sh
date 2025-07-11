#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh" || exit 2

# インストール実行フラグ
installation_performed=false

# Mac のシステム設定を適用
setup_mac_settings() {
    echo "==== Start: "Mac のシステム設定を適用中...""
    
    # 設定ファイルの存在確認
    local settings_file="$REPO_ROOT/config/macos/settings.sh"
    if [[ ! -f "$settings_file" ]]; then
        echo "[WARN] "config/macos/settings.sh が見つかりません""
        exit 2
    fi
    
    # 設定ファイルの内容を確認
    echo "[INFO] "📝 Mac 設定ファイルをチェック中...""
    local setting_count=$(grep -v "^#" "$settings_file" | grep -v "^$" | grep -E "defaults write" | wc -l | tr -d ' ')
    echo "[INFO] "🔍 $setting_count 個の設定項目が検出されました""
    
    # CI環境では適用のみスキップ
    if [ "$IS_CI" = "true" ]; then
        echo "[INFO] "ℹ️ CI環境では Mac システム設定の適用をスキップします（検証のみ実行）""
        
        # 主要な設定カテゴリを確認
        for category in "Dock" "Finder" "screenshots"; do
            if grep -q "$category" "$settings_file"; then
                echo "[SUCCESS] "$category に関する設定が含まれています""
            fi
        done
        
        return 0
    fi
    
    # 非CI環境では設定を適用
    if ! source "$settings_file" 2>/dev/null; then
        echo "[WARN] "Mac 設定の適用中に一部エラーが発生しましたが、続行します""
    else
        installation_performed=true
        echo "[SUCCESS] "Mac のシステム設定が適用されました""
    fi
    
    # 設定が正常に適用されたか確認（一部の設定のみ）
    check_settings_applied
    
    return 0
}

# 設定が適用されたかチェック
check_settings_applied() {
    for setting in "com.apple.dock" "com.apple.finder"; do
        if defaults read "$setting" &>/dev/null; then
            echo "[SUCCESS] "${setting##*.} の設定が正常に適用されました""
        else
            echo "[WARN] "${setting##*.} の設定の適用に問題がある可能性があります""
        fi
    done
}

# Mac環境を検証する関数
verify_mac_setup() {
    echo "==== Start: "Mac環境を検証中...""
    local verification_failed=false
    
    # macOSバージョンの確認
    OS_VERSION=$(sw_vers -productVersion)
    if [ -z "$OS_VERSION" ]; then
        echo "[ERROR] "macOSバージョンを取得できません""
        verification_failed=true
    else
        echo "[SUCCESS] "macOSバージョン: $OS_VERSION""
    fi
    
    # macOS設定の確認
    verify_macos_preferences
    
    # システム整合性の確認
    verify_system_integrity
    
    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] "Mac環境の検証に失敗しました""
        return 1
    else
        echo "[SUCCESS] "Mac環境の検証が完了しました""
        return 0
    fi
}

# macOS設定ファイルの検証
verify_macos_preferences() {
    if [ -f "$HOME/Library/Preferences/com.apple.finder.plist" ]; then
        echo "[SUCCESS] "Finder設定ファイルが存在します""
    else
        echo "[WARN] "Finder設定ファイルが見つかりません""
    fi
    
    if [ -f "$HOME/Library/Preferences/com.apple.dock.plist" ]; then
        echo "[SUCCESS] "Dock設定ファイルが存在します""
    else
        echo "[WARN] "Dock設定ファイルが見つかりません""
    fi
}

# システム整合性保護の検証
verify_system_integrity() {
    if csrutil status | grep -q "enabled"; then
        echo "[SUCCESS] "システム整合性保護が有効です""
    else
        echo "[WARN] "システム整合性保護が無効になっています""
    fi
}

# メイン関数
main() {
    echo "==== Start: "macOS環境のセットアップを開始します""
    
    setup_mac_settings
    
    echo "[SUCCESS] "macOS環境のセットアップが完了しました""
    
    # 終了ステータスの決定
    if [ "$installation_performed" = "true" ]; then
        exit 0  # インストール実行済み
    else
        exit 1  # インストール不要（冪等性保持）
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 