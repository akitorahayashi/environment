#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    echo "[Start] Mac のシステム設定を適用中..."
    
    # 設定ファイルの存在確認
    local settings_file="$REPO_ROOT/config/macos/macos-settings.sh"
    if [[ ! -f "$settings_file" ]]; then
        echo "[WARN] config/macos/macos-settings.sh が見つかりません"
        exit 1
    fi
    
    # 設定を適用
    if ! source "$settings_file" 2>/dev/null; then
        echo "[WARN] Mac 設定の適用中に一部エラーが発生しましたが、続行します"
    else
        echo "[SUCCESS] Mac のシステム設定が適用されました"
    fi
}

verify_mac_setup() {
    echo "==== Start: macOS設定を検証中... ===="
    
    # 設定ファイルの存在確認
    local settings_file="$REPO_ROOT/config/macos/macos-settings.sh"
    if [[ -f "$settings_file" ]]; then
        echo "[SUCCESS] macOS設定ファイルが存在します: $settings_file"
        echo "[SUCCESS] macOS設定の検証が完了しました"
        return 0
    else
        echo "[ERROR] macOS設定ファイルが見つかりません: $settings_file"
        return 1
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi