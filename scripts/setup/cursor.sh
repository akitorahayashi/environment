#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Cursor のセットアップ
setup_cursor() {
    log_start "Cursor のセットアップを開始します..."

    # Cursor がインストールされているか確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return
    else
        log_installed "Cursor"
    fi

    # Cursor 設定ディレクトリの作成（存在しない場合）
    CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
    if [[ ! -d "$CURSOR_CONFIG_DIR" ]]; then
        mkdir -p "$CURSOR_CONFIG_DIR"
        log_success "Cursor 設定ディレクトリを作成しました"
    fi

    # 設定の復元スクリプトが存在するか確認し、実行
    if [[ -f "$REPO_ROOT/cursor/restore_cursor_settings.sh" ]]; then
        log_start "Cursor 設定を復元しています..."
        bash "$REPO_ROOT/cursor/restore_cursor_settings.sh"
        
        # 設定ファイルが正しく復元されたか確認
        REQUIRED_SETTINGS=("settings.json" "keybindings.json" "extensions.json")
        for setting in "${REQUIRED_SETTINGS[@]}"; do
            if [[ -f "$CURSOR_CONFIG_DIR/$setting" ]]; then
                log_success "$setting が正常に復元されました"
            else
                log_warning "$setting の復元に失敗しました"
            fi
        done
    else
        log_warning "Cursor の復元スクリプトが見つかりません。設定の復元をスキップします。"
    fi

    # Flutter SDK のパスを Cursor に適用
    if command_exists flutter; then
        FLUTTER_PATH=$(which flutter)
        FLUTTER_SDK_PATH=$(dirname $(dirname $(readlink -f "$FLUTTER_PATH")))
        
        if [[ -d "$FLUTTER_SDK_PATH" ]]; then
            CURSOR_SETTINGS="$CURSOR_CONFIG_DIR/settings.json"
            
            log_start "Flutter SDK のパスを Cursor に適用中..."
            if [[ -f "$CURSOR_SETTINGS" ]]; then
                # 現在のFlutterパス設定を確認
                CURRENT_PATH=$(cat "$CURSOR_SETTINGS" | grep -o '"dart.flutterSdkPath": "[^"]*"' | cut -d'"' -f4 || echo "")
                
                if [[ "$CURRENT_PATH" != "$FLUTTER_SDK_PATH" ]]; then
                    # settings.jsonにFlutter SDKパスを追加
                    if ! command_exists jq; then
                        log_warning "jqコマンドが見つかりません。手動でsettings.jsonを更新してください。"
                    else
                        jq --arg path "$FLUTTER_SDK_PATH" '.["dart.flutterSdkPath"] = $path' "$CURSOR_SETTINGS" > "${CURSOR_SETTINGS}.tmp" && mv "${CURSOR_SETTINGS}.tmp" "$CURSOR_SETTINGS"
                        log_success "Flutter SDK のパスを $FLUTTER_SDK_PATH に更新しました！"
                    fi
                else
                    log_success "Flutter SDK のパスはすでに正しく設定されています"
                fi
            else
                log_warning "Cursor の設定ファイルが見つかりません"
            fi
        else
            log_warning "Flutter SDK のパスを特定できませんでした"
        fi
    fi

    log_success "Cursor のセットアップ完了"
}

# MARK: - Verify

# Cursor環境を検証する関数
verify_cursor_setup() {
    log_start "Cursor環境を検証中..."
    local verification_failed=false
    
    # Cursorアプリケーションの確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_error "Cursor.appが見つかりません"
        verification_failed=true
    else
        log_installed "Cursor"
        
        # Cursor設定ディレクトリの確認
        CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
        if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
            log_error "Cursor設定ディレクトリが見つかりません"
            verification_failed=true
        else
            log_success "Cursor設定ディレクトリが存在します"
            
            # 必要な設定ファイルの確認
            REQUIRED_SETTINGS=("settings.json" "keybindings.json" "extensions.json")
            for file in "${REQUIRED_SETTINGS[@]}"; do
                if [ ! -f "$CURSOR_CONFIG_DIR/$file" ]; then
                    log_error "Cursor設定ファイル $file が見つかりません"
                    verification_failed=true
                else
                    log_success "Cursor設定ファイル $file が存在します"
                fi
            done
        fi
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Cursor環境の検証に失敗しました"
        return 1
    else
        log_success "Cursor環境の検証が完了しました"
        return 0
    fi
} 