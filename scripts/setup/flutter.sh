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
    else
        log_installed "Flutter"
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
    
    # Flutter doctorの実行（CI環境では簡易出力のみ）
    log_start "Flutter環境を確認中..."
    if [ "$IS_CI" = "true" ]; then
        # CI環境では簡易バージョンのみ実行（パイプエラー回避）
        flutter --version > /dev/null 2>&1 || true
        log_info "CI環境: Flutter のバージョン確認のみ実行しました"
    else
        # 通常環境では完全なdoctor実行
        flutter doctor || true
    fi

    log_success "Flutter の環境設定が完了しました"
}

# Flutter環境を検証
verify_flutter_setup() {
    log_start "Flutter環境を検証中..."
    local verification_failed=false
    
    # インストール確認
    if ! verify_flutter_installation; then
        return 1
    fi
    
    # パス確認
    verify_flutter_path || verification_failed=true
    
    # 環境チェック
    verify_flutter_environment || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Flutter環境の検証に失敗しました"
        return 1
    else
        log_success "Flutter環境の検証が完了しました"
        return 0
    fi
}

# Flutterのインストール確認
verify_flutter_installation() {
    if ! command_exists flutter; then
        log_error "Flutterがインストールされていません"
        return 1
    fi
    log_installed "Flutter"
    return 0
}

# Flutterのパス確認
verify_flutter_path() {
    FLUTTER_PATH=$(which flutter)
    log_info "Flutter PATH: $FLUTTER_PATH"
    
    # ARMデバイスでのパス検証
    if [[ "$(uname -m)" == "arm64" ]] && [[ "$FLUTTER_PATH" != "/opt/homebrew/bin/flutter" ]]; then
        log_error "Flutterのパスが想定と異なります"
        log_error "期待: /opt/homebrew/bin/flutter"
        log_error "実際: $FLUTTER_PATH"
        return 1
    else
        log_success "Flutterのパスが正しく設定されています"
        return 0
    fi
}

# Flutter環境の検証
verify_flutter_environment() {
    # CI環境でのチェック方法分岐
    if [ "$IS_CI" = "true" ]; then
        verify_flutter_ci_environment
        return $?
    else
        verify_flutter_full_environment
        return $?
    fi
}

# CI環境でのFlutter検証（簡易版）
verify_flutter_ci_environment() {
    log_info "CI環境: flutter doctor のチェックを実行中..."
    
    # バージョン確認のみ
    if ! flutter --version > /dev/null 2>&1; then
        log_error "flutter --version の実行に失敗しました"
        return 1
    fi
    log_success "Flutterコマンドが正常に動作しています"
    
    # Xcodeとの連携確認（出力パイプを使わない方法）
    if flutter doctor 2>&1 | grep -q "Xcode"; then
        log_success "XcodeがFlutterから認識されています" 
    else
        log_warning "Xcode検出確認に問題がある可能性があります"
    fi
    
    return 0
}

# 通常環境でのFlutter検証（完全版）
verify_flutter_full_environment() {
    log_info "flutter doctor を実行中..."
    if ! flutter doctor -v; then
        log_error "flutter doctorの実行に失敗しました"
        return 1
    fi
    
    # Xcodeとの連携確認
    if ! flutter doctor -v | grep -q "Xcode"; then
        log_error "XcodeがFlutterから認識されていません"
        return 1
    fi
    log_success "XcodeがFlutterから認識されています"
    
    return 0
} 