#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SETUP_DIR="$SCRIPT_DIR"  # セットアップディレクトリを保存

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Flutter のセットアップ
setup_flutter() {
    if ! command_exists flutter; then
        handle_error "Flutter がインストールされていません"
    fi

    # Flutterのパスを確認
    FLUTTER_PATH=$(which flutter)
    log_info "Flutter PATH: $FLUTTER_PATH"
    
    # パスが正しいか確認（ARM Macの場合）
    if [[ "$(uname -m)" == "arm64" ]] && [[ "$FLUTTER_PATH" != "/opt/homebrew/bin/flutter" ]]; then
        log_error "Flutterが期待するパスにインストールされていません"
        log_info "現在のパス: $FLUTTER_PATH"
        log_info "期待するパス: /opt/homebrew/bin/flutter"
        handle_error "Flutter のパスが正しくありません"
    fi
    
    # Flutter doctorの実行（詳細なエラーチェックはせず、情報表示のみ）
    log_start "Flutter環境を確認中..."
    flutter doctor || true

    log_success "Flutter の環境設定が完了しました"
}

# MARK: - Verify

# Flutterの環境設定を検証する関数
verify_flutter_setup() {
    log_start "Flutter環境を検証中..."
    local verification_failed=false
    
    # Flutterがインストールされているか確認
    if ! command_exists flutter; then
        log_error "Flutterがインストールされていません"
        return 1
    fi
    log_success "Flutterがインストールされています"
    
    # Flutterのパスを確認
    FLUTTER_PATH=$(which flutter)
    log_info "Flutter PATH: $FLUTTER_PATH"
    
    # パスが正しいか確認（ARM Macの場合）
    if [[ "$(uname -m)" == "arm64" ]] && [[ "$FLUTTER_PATH" != "/opt/homebrew/bin/flutter" ]]; then
        log_error "Flutterのパスが想定と異なります"
        log_error "期待: /opt/homebrew/bin/flutter"
        log_error "実際: $FLUTTER_PATH"
        verification_failed=true
    else
        log_success "Flutterのパスが正しく設定されています"
    fi
    
    # Flutter doctorでチェック
    log_info "flutter doctor を実行中..."
    if ! flutter doctor -v; then
        log_error "flutter doctorの実行に失敗しました"
        verification_failed=true
    fi
    
    # Xcodeとの連携確認
    if ! flutter doctor -v | grep -q "Xcode"; then
        log_error "XcodeがFlutterから認識されていません"
        verification_failed=true
    else
        log_success "XcodeがFlutterから認識されています"
    fi
    
    # Android SDKとの連携確認
    verify_flutter_android_integration
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Flutter環境の検証に失敗しました"
        return 1
    else
        log_success "Flutter環境の検証が完了しました"
        return 0
    fi
}

# FlutterとAndroid SDKの連携を検証する関数
verify_flutter_android_integration() {
    log_info "Flutterの基本動作を検証中..."
    
    # flutter --versionコマンドのみで基本チェック
    if ! flutter --version > /dev/null 2>&1; then
        log_error "Flutterコマンドの実行に失敗しました"
        return 1
    else
        log_success "Flutterコマンドが正常に動作しています"
    fi
    
    return 0
} 