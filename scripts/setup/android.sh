#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Android SDK環境の初期設定
setup_android_sdk_env() {
    # Android SDK の環境変数を設定
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
    
    # Android SDK ディレクトリが存在するか確認（スキップ可能）
    if [ "$IS_CI" = "true" ]; then
        # CI環境では確認しない（すでに存在するか、後で作成される）
        mkdir -p "$ANDROID_SDK_ROOT" 2>/dev/null || true
    else
        # 通常環境では情報表示
        if [ ! -d "$ANDROID_SDK_ROOT" ]; then
            log_info "Android SDK ディレクトリを作成します..."
            mkdir -p "$ANDROID_SDK_ROOT"
        fi
    fi
    
    # コマンドラインツールのパス
    CMDLINE_TOOLS_PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest"
    export CMDLINE_TOOLS_PATH
    
    # CI環境では詳細なログを出力しない
    [ "$IS_CI" != "true" ] && log_success "Android SDK環境変数を設定しました"
}

# Android SDKライセンスに同意する関数
accept_android_licenses() {
    local auto_accept=${1:-false}
    
    log_start "Android SDK ライセンスに同意中..."
    
    # CI環境またはauto_acceptが指定された場合は自動同意
    if [ "$auto_accept" = "true" ] || [ "$IS_CI" = "true" ]; then
        log_info "Android SDKライセンスに自動同意します"
        
        # 両方のライセンス同意コマンドを一括実行（エラーを無視）
        (yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses > /dev/null 2>&1) || true
        (yes | flutter doctor --android-licenses > /dev/null 2>&1) || true
        
        log_success "Android SDK ライセンスの同意処理を完了しました"
        return 0
    fi
    
    # 通常環境では、ライセンス同意が必要かチェックし、必要なら実行
    if flutter doctor 2>&1 | grep -q "Some Android licenses not accepted"; then
        log_info "Android SDK ライセンスの同意が必要です"
        
        # ユーザーに同意を促す
        read -p "Android SDK ライセンスに同意しますか？ (Y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            # 同意処理を実行（出力は表示）
            yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses || true
            yes | flutter doctor --android-licenses || true
            log_success "Android SDK ライセンスの同意処理を完了しました"
        else
            log_warning "Android SDK ライセンスへの同意をスキップしました"
        fi
    else
        log_success "Android SDK ライセンスはすでに同意済みです"
    fi
}

# Android SDKコンポーネントをインストールする関数
install_android_sdk_components() {
    log_info "Android SDKコンポーネントの設定をスキップします..."
    log_info "必要なコンポーネントはAndroid Studioの起動時に自動的にインストールされます"
    
    # platform-toolsのみが存在するか確認（基本機能用）
    if [ ! -d "$ANDROID_SDK_ROOT/platform-tools" ] && [ "$IS_CI" != "true" ]; then
        log_info "基本的なAndroid SDKツールを設定中..."
        # platform-toolsのみインストール
        (echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" "platform-tools" > /dev/null 2>&1) || true
    fi
    
    # 環境変数設定の確認
    if [ -d "$ANDROID_SDK_ROOT" ]; then
        log_success "Android SDK の基本設定が完了しました"
    fi
} 