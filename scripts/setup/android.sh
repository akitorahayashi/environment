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
    
    # Android SDK ディレクトリが存在するか確認
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        log_info "Android SDK ディレクトリを作成します..."
        mkdir -p "$ANDROID_SDK_ROOT"
    fi
    
    # コマンドラインツールのパス
    CMDLINE_TOOLS_PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest"
    
    # 環境変数をエクスポート
    export CMDLINE_TOOLS_PATH
    
    log_success "Android SDK環境変数を設定しました"
}

# Android SDKライセンスに同意する関数
accept_android_licenses() {
    local auto_accept=${ANDROID_LICENSES:-false}
    
    log_start "Android SDK ライセンスに同意中..."
    
    if [ "$auto_accept" = "true" ] || [ "$IS_CI" = "true" ]; then
        # 全てのライセンスに自動で同意（エラー処理を改善）
        log_info "自動的にAndroid SDKライセンスに同意します"
        yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses > /dev/null 2>&1 || log_warning "Android SDK ライセンスへの同意に一部問題がありました"
        yes | flutter doctor --android-licenses || log_warning "Flutter Android ライセンスへの同意に一部問題がありました"
        log_success "Android SDK ライセンスに同意しました"
    else
        # ライセンス同意状態を確認
        if ! flutter doctor | grep -q "Some Android licenses not accepted"; then
            log_success "Android SDK ライセンスはすでに同意済みです"
        
            log_info "Android SDK ライセンスへの同意が必要です"
            if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
                # sdkmanager ライセンスに同意（エラー処理を改善）
                {
                    yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses 
                } > /dev/null 2>&1 || log_warning "sdkmanager ライセンスへの同意で問題が発生しましたが、続行します"
                
                # Flutter Android ライセンスに明示的に同意（標準出力はリダイレクトせず）
                log_info "Flutter の Android ライセンスに同意します..."
                # 出力をリダイレクトせずに実行
                {
                    yes | flutter doctor --android-licenses
                } || log_warning "flutter doctor --android-licenses で問題が発生しましたが、続行します"
                
                # 最終確認 - 成功したかどうかにかかわらず続行
                if flutter doctor | grep -q "Some Android licenses not accepted"; then
                    log_warning "Android ライセンスの同意が完全ではありません。手動で確認してください"
                    log_info "手動で次のコマンドを実行してください: flutter doctor --android-licenses"
                else
                    log_success "Android SDK ライセンスに同意しました"
                fi
            fi
        fi
    fi
    
    # Flutterのdoctorを実行して最終状態を確認
    log_info "Flutter doctorでライセンス状態を確認中..."
    flutter doctor -v | grep -A 5 "Android toolchain" || true
}

# Android SDKコンポーネントをインストールする関数
install_android_sdk_components() {
    log_start "Android SDK コンポーネントを確認中..."
    
    # sdkmanagerの存在確認
    if [ ! -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
        handle_error "sdkmanager が見つかりません: $CMDLINE_TOOLS_PATH/bin/sdkmanager"
    fi
    
    # 必要なコンポーネントのリスト
    SDK_COMPONENTS=(
        "platform-tools"
        "build-tools;35.0.1"
        "platforms;android-34"
        "platforms;android-33"
        "platforms;android-32"
        "build-tools;33.0.0"
        "build-tools;32.0.0"
        "build-tools;31.0.0"
    )
    
    # インストール済みパッケージの取得
    log_info "インストール済みパッケージを確認中..."
    INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list --sdk_root="$ANDROID_SDK_ROOT" 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
    
    # 各コンポーネントをチェックしてインストール
    for component in "${SDK_COMPONENTS[@]}"; do
        log_info "コンポーネント '$component' を確認中..."
        
        # インストール済みかチェック
        if echo "$INSTALLED_PACKAGES" | grep -q "$component"; then
            log_success "$component はすでにインストール済み"
            continue
        fi
        
        # インストールを試みる
        log_start "$component をインストール中..."
        if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" "$component" > /dev/null; then
            log_success "$component のインストールが完了しました"
        else
            log_warning "$component のインストールに失敗しました"
            
            # CI環境での特別な処理
            if [ "$IS_CI" = "true" ]; then
                log_info "CI環境での代替インストールを試みます..."
                # 代替のインストール方法を試す
                if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --install "$component" > /dev/null; then
                    log_success "$component の代替インストールが成功しました"
                else
                    log_warning "$component の代替インストールも失敗しました"
                    # CI環境では一部のコンポーネントが失敗しても続行
                    continue
                fi
            else
                # ローカル環境ではユーザーに確認
                read -p "$component のインストールに失敗しました。続行しますか？ (y/N): " -n 1 -r
                echo
                if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                    handle_error "$component のインストールに失敗しました"
                fi
            fi
        fi
    done
    
    # インストール後の最終確認
    log_info "インストール結果を確認中..."
    "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --list > /dev/null
    if [ $? -eq 0 ]; then
        log_success "Android SDK コンポーネントの確認が完了しました"
    else
        log_warning "インストール結果の確認に失敗しましたが、続行します"
    fi
} 