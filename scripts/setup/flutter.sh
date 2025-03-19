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
        accept_android_licenses true
    else
        # 必要な場合のみライセンス同意を促す
        flutter doctor 2>&1 | grep -q "Some Android licenses not accepted" && {
            log_info "Android SDKライセンスへの同意が必要かもしれません"
            log_info "AndroidStudioの初回起動時、またはflutter doctor --android-licensesコマンドで同意できます"
        }
    fi
    
    # Flutter doctorの実行（詳細なエラーチェックはせず、情報表示のみ）
    log_start "Flutter環境を確認中..."
    flutter doctor || true

    log_success "Flutter の環境設定が完了しました"
} 