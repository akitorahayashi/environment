#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SETUP_DIR="$SCRIPT_DIR"  # セットアップディレクトリを保存

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
# Android SDK関連の関数をロード
source "$SETUP_DIR/android.sh"

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

    # Android SDK環境のセットアップ
    log_start "Android SDK の基本設定を行います..."
    setup_android_sdk_env
    
    # 最低限のツールが利用可能か簡易チェック
    if ! command_exists java; then
        log_warning "Javaが見つかりません。Android開発には必要です"
    fi
    
    # コマンドラインツールのパスをセットアップ（最小限の処理）
    if [ ! -d "$CMDLINE_TOOLS_PATH" ] && command_exists brew; then
        # Homebrew でインストールされた Android SDK Command Line Tools のパス
        BREW_CMDLINE_TOOLS="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest"
        
        if [ -d "$BREW_CMDLINE_TOOLS" ]; then
            log_info "コマンドラインツールのシンボリックリンクを作成..."
            mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
            create_symlink "$BREW_CMDLINE_TOOLS" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
        fi
    fi
    
    # Android SDKコンポーネントの最小限の設定
    install_android_sdk_components
    
    # ライセンスの同意（CI環境では自動同意、通常環境ではスキップ可能）
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境ではAndroid SDKライセンスに自動同意します"
        export ANDROID_LICENSES=true
        accept_android_licenses
    else
        # 必要な場合のみライセンス同意を促す
        flutter doctor 2>&1 | grep -q "Some Android licenses not accepted" && {
            log_info "Android SDKライセンスへの同意が必要かもしれません"
            log_info "AndroidStudioの初回起動時、またはflutter doctor --android-licensesコマンドで同意できます"
            
            # ユーザーに同意するか確認
            read -p "Android SDKライセンスに今すぐ同意しますか？ (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                accept_android_licenses
            fi
        }
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
    log_info "FlutterとAndroid SDKの連携を検証中..."
    local integration_failed=false
    
    # Android toolchainの状態確認
    ANDROID_OUTPUT=$(flutter doctor -v | grep -A 10 "Android toolchain")
    
    # Android SDKの検出確認
    if ! echo "$ANDROID_OUTPUT" | grep -q "Android SDK"; then
        log_error "Android SDKがFlutterから検出されていません"
        integration_failed=true
    else
        log_success "Android SDKがFlutterから検出されています"
    fi
    
    # ライセンス同意確認
    if echo "$ANDROID_OUTPUT" | grep -q "Some Android licenses not accepted"; then
        log_warning "Android SDKライセンスに未同意のものがあります"
    else
        log_success "Android SDKライセンスに同意済みです"
    fi
    
    if [ "$integration_failed" = "true" ]; then
        log_error "FlutterとAndroid SDKの連携に問題があります"
        return 1
    else
        log_success "FlutterとAndroid SDKの連携は正常です"
        return 0
    fi
} 