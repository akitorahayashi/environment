#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/../utils/helpers.sh"

# Cursor のセットアップ
setup_cursor() {
    log_start "Cursor のセットアップを開始します..."
    
    # インストール確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return
    fi
    log_installed "Cursor"
    
    # 設定ディレクトリを作成
    CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
    if [[ ! -d "$CURSOR_CONFIG_DIR" ]]; then
        mkdir -p "$CURSOR_CONFIG_DIR"
        log_success "Cursor 設定ディレクトリを作成しました"
    fi
    
    # 設定を復元
    restore_settings_script="$REPO_ROOT/cursor/restore_cursor_settings.sh"
    if [[ -f "$restore_settings_script" ]]; then
        log_start "Cursor 設定を復元しています..."
        bash "$restore_settings_script"
        
        # 復元を確認
        SETTINGS_FILES=("settings.json" "keybindings.json" "extensions.json")
        for file in "${SETTINGS_FILES[@]}"; do
            if [[ -f "$CURSOR_CONFIG_DIR/$file" ]]; then
                log_success "$file が正常に復元されました"
            else
                log_warning "$file の復元に失敗しました"
            fi
        done
    else
        log_warning "Cursor の復元スクリプトが見つかりません。設定の復元をスキップします。"
    fi
    
    # Flutter SDK のパスを設定
    if command_exists flutter; then
        FLUTTER_PATH=$(which flutter)
        FLUTTER_SDK_PATH=$(dirname $(dirname $(readlink -f "$FLUTTER_PATH")))
        
        if [[ -d "$FLUTTER_SDK_PATH" ]]; then
            CURSOR_SETTINGS="$CURSOR_CONFIG_DIR/settings.json"
            
            log_start "Flutter SDK のパスを Cursor に適用中..."
            if [[ -f "$CURSOR_SETTINGS" ]]; then
                # 現在の設定を確認
                CURRENT_PATH=$(cat "$CURSOR_SETTINGS" | grep -o '"dart.flutterSdkPath": "[^"]*"' | cut -d'"' -f4 || echo "")
                
                if [[ "$CURRENT_PATH" != "$FLUTTER_SDK_PATH" ]]; then
                    # settings.jsonを更新
                    if ! command_exists jq; then
                        log_warning "jqコマンドが見つかりません。手動でsettings.jsonを更新してください。"
                    else
                        jq --arg path "$FLUTTER_SDK_PATH" \
                           '.["dart.flutterSdkPath"] = $path' \
                           "$CURSOR_SETTINGS" > "${CURSOR_SETTINGS}.tmp" && \
                        mv "${CURSOR_SETTINGS}.tmp" "$CURSOR_SETTINGS"
                        
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

# Cursor環境を検証
verify_cursor_setup() {
    log_start "Cursor環境を検証中..."
    local verification_failed=false
    
    # アプリケーションを確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_error "Cursor.appが見つかりません"
        verification_failed=true
    else
        log_installed "Cursor"
        
        # 設定ディレクトリを確認
        CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
        if [ ! -d "$CURSOR_CONFIG_DIR" ]; then
            log_error "Cursor設定ディレクトリが見つかりません"
            verification_failed=true
        else
            log_success "Cursor設定ディレクトリが存在します"
            
            # 設定ファイルを確認
            SETTINGS_FILES=("settings.json" "keybindings.json" "extensions.json")
            for file in "${SETTINGS_FILES[@]}"; do
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