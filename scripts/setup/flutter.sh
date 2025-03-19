#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
# Android SDK関連の関数をロード
source "$SCRIPT_DIR/android.sh"

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
    log_start "Android SDK のセットアップを確認中..."
    setup_android_sdk_env
    
    # android-commandlinetoolsとJavaが利用可能か確認
    if ! command_exists sdkmanager; then
        handle_error "Android Command Line Toolsが見つかりません"
    fi
    
    if ! command_exists java; then
        handle_error "Javaが見つかりません"
    fi
    
    # cmdline-tools のパスが正しいか確認
    if [ ! -d "$CMDLINE_TOOLS_PATH" ]; then
        log_start "Android SDK のコマンドラインツールをセットアップ中..."
        
        # Homebrew でインストールされた Android SDK Command Line Tools のパス
        BREW_CMDLINE_TOOLS="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest"
        
        if [ -d "$BREW_CMDLINE_TOOLS" ]; then
            log_info "Homebrew でインストールされたコマンドラインツールを設定中..."
            
            # cmdline-tools ディレクトリ構造を作成
            mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
            
            # latest シンボリックリンクを作成
            create_symlink "$BREW_CMDLINE_TOOLS" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
            log_success "Android SDK コマンドラインツールをセットアップしました"
        else
            handle_error "Homebrew の Android SDK コマンドラインツールが見つかりません"
        fi
    fi
    
    # Android SDKコンポーネントのインストール
    install_android_sdk_components
    
    # ライセンスの同意
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境でもAndroid SDKライセンスに自動同意します"
        accept_android_licenses true
    else
        accept_android_licenses false
    fi
    
    # Flutter doctorの実行
    log_start "Flutter doctor を実行中..."
    if ! flutter doctor -v; then
        handle_error "flutter doctor の実行に問題があります"
    fi

    log_success "Flutter の環境のセットアップ完了"
} 