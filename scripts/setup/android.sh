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
        mkdir -p "$ANDROID_SDK_ROOT" || handle_error "Android SDK ディレクトリの作成に失敗しました"
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
    local license_error=false
    
    log_start "Android SDK ライセンスに同意中..."
    
    if [ "$auto_accept" = "true" ] || [ "$IS_CI" = "true" ]; then
        # 全てのライセンスに自動で同意（エラー処理を改善）
        log_info "自動的にAndroid SDKライセンスに同意します"
        if ! yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses > /dev/null 2>&1; then
            log_error "Android SDK ライセンスへの同意に失敗しました"
            license_error=true
        fi
        
        if ! yes | flutter doctor --android-licenses; then
            log_error "Flutter Android ライセンスへの同意に失敗しました"
            license_error=true
        fi
        
        if [ "$license_error" = "true" ] && [ "$IS_CI" = "true" ]; then
            handle_error "CI環境でのライセンス同意に失敗しました。処理を中止します"
        elif [ "$license_error" = "true" ]; then
            log_warning "ライセンス同意で問題が発生しましたが、処理を続行します"
        else
            log_success "Android SDK ライセンスに同意しました"
        fi
    else
        # ライセンス同意状態を確認
        if ! flutter doctor | grep -q "Some Android licenses not accepted"; then
            log_success "Android SDK ライセンスはすでに同意済みです"
        else
            log_info "Android SDK ライセンスへの同意が必要です"
            if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
                # sdkmanager ライセンスに同意（エラー処理を改善）
                if ! yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --licenses > /dev/null 2>&1; then
                    log_error "sdkmanager ライセンスへの同意に失敗しました"
                    license_error=true
                fi
                
                # Flutter Android ライセンスに明示的に同意
                log_info "Flutter の Android ライセンスに同意します..."
                if ! yes | flutter doctor --android-licenses; then
                    log_error "flutter doctor --android-licenses での同意に失敗しました"
                    license_error=true
                fi
                
                # 最終確認 - 成功したかどうかにかかわらず続行
                if flutter doctor | grep -q "Some Android licenses not accepted"; then
                    log_warning "Android ライセンスの同意が完全ではありません。手動で確認してください"
                    log_info "手動で次のコマンドを実行してください: flutter doctor --android-licenses"
                    
                    # ライセンス同意が絶対に必要な場合は処理を停止するオプション
                    if [ "${STRICT_LICENSE_CHECK:-false}" = "true" ]; then
                        handle_error "ライセンス同意が完了していません。STRICT_LICENSE_CHECK が有効なため処理を中止します"
                    fi
                else
                    log_success "Android SDK ライセンスに同意しました"
                fi
            else
                handle_error "sdkmanager が見つかりません: $CMDLINE_TOOLS_PATH/bin/sdkmanager"
            fi
        fi
    fi
    
    # Flutterのdoctorを実行して最終状態を確認
    log_info "Flutter doctorでライセンス状態を確認中..."
    flutter doctor -v | grep -A 5 "Android toolchain" || true
}

# Android SDKコンポーネントをインストールする関数
install_android_sdk_components() {
    log_start "Android SDK コンポーネントをインストール中..."
    local install_errors=0
    # 全てのコンポーネントは開発に必須
    local allow_failure=${ALLOW_COMPONENT_FAILURE:-false}
    
    # sdkmanagerの存在確認
    if [ ! -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
        handle_error "sdkmanager が見つかりません: $CMDLINE_TOOLS_PATH/bin/sdkmanager"
    fi
    
    # 開発に必要なコンポーネントのリスト
    SDK_COMPONENTS=(
        "platform-tools"
        "build-tools;34.0.0"
        "platforms;android-34"
        "platforms;android-33"
        "platforms;android-32"
        "build-tools;33.0.0"
        "build-tools;32.0.0"
        "build-tools;31.0.0"
    )
    
    # インストール済みパッケージの取得
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境のため、パッケージ確認をスキップして直接インストールを行います"
        INSTALLED_PACKAGES=""
    else
        log_info "インストール済みパッケージを確認中..."
        INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list --sdk_root="$ANDROID_SDK_ROOT" 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
        if [ $? -ne 0 ]; then
            log_warning "インストール済みパッケージの確認に失敗しましたが、続行します"
        fi
    fi
    
    # 各コンポーネントをチェックしてインストール
    for component in "${SDK_COMPONENTS[@]}"; do
        log_info "コンポーネント '$component' を確認中..."
        # 全てのコンポーネントが開発に必須
        local is_critical=true
        
        # CI環境または確認でパッケージが見つからない場合、インストールを試みる
        if [ "$IS_CI" = "true" ] || ! echo "$INSTALLED_PACKAGES" | grep -q "$component"; then
            # CIの場合は常にインストール、それ以外は未インストールの場合のみ
            if [ "$IS_CI" != "true" ]; then
                log_info "$component をインストールします"
            fi
            
            # インストールを試みる
            log_start "$component をインストール中..."
            install_success=false
            
            # 通常のインストール方法を試す
            if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" "$component" > /dev/null; then
                log_success "$component のインストールが完了しました"
                install_success=true
            else
                log_warning "$component のインストールが通常の方法では失敗しました"
                
                # 代替のインストール方法を試す
                if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --sdk_root="$ANDROID_SDK_ROOT" --install "$component" > /dev/null; then
                    log_success "$component の代替インストールが成功しました"
                    install_success=true
                else
                    log_error "$component のインストールに失敗しました"
                    # インストールが失敗したら全処理を中断
                    handle_error "コンポーネント '$component' のインストールに失敗しました。処理を中止します"
                fi
            fi
        else
            log_success "$component はすでにインストール済み"
        fi
    done
    
    log_success "すべてのAndroid SDK コンポーネントのインストールが完了しました"
}

# MARK: - Verify

# Android SDKのセットアップを検証する関数
verify_android_sdk_setup() {
    log_start "Android SDK環境を検証中..."
    local verification_failed=false
    
    # Android SDK環境変数の設定
    export ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
    
    # Android SDKディレクトリの確認
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        log_error "Android SDKディレクトリが存在しません"
        verification_failed=true
    else
        log_success "Android SDKディレクトリが設定されています: $ANDROID_SDK_ROOT"
    fi
    
    # コマンドラインツールのパスを確認
    CMDLINE_TOOLS_PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest"
    if [ ! -d "$CMDLINE_TOOLS_PATH" ]; then
        log_error "Android SDK コマンドラインツールがセットアップされていません"
        verification_failed=true
    else
        log_success "Android SDK コマンドラインツールがセットアップされています"
    fi
    
    # sdkmanagerの存在確認
    if [ ! -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
        log_error "sdkmanager が見つかりません: $CMDLINE_TOOLS_PATH/bin/sdkmanager"
        verification_failed=true
    else
        log_success "sdkmanager が正しく設定されています"
    fi
    
    # platform-toolsの確認（最低限必要なコンポーネント）
    if [ ! -d "$ANDROID_SDK_ROOT/platform-tools" ]; then
        log_error "platform-toolsがセットアップされていません"
        verification_failed=true
    else
        log_success "platform-toolsがセットアップされています"
    fi
    
    # 重要なコンポーネントの確認
    verify_android_components
    
    # Flutterとの連携を確認
    if command -v flutter &>/dev/null; then
        log_info "Flutter doctorでAndroid環境を確認中..."
        if ! flutter doctor -v | grep -A 5 "Android toolchain"; then
            log_warning "Flutter doctorでAndroid環境の確認に問題がある可能性があります"
        fi
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Android SDK環境の検証に失敗しました"
        return 1
    else
        log_success "Android SDK環境の検証が完了しました"
        return 0
    fi
}

# Android SDKコンポーネントの存在を確認する関数
verify_android_components() {
    # すべてのSDKコンポーネントを検証
    local missing_components=0
    
    log_info "Android SDK コンポーネントを確認中..."
    
    # インストール済みパッケージの取得
    INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list --sdk_root="$ANDROID_SDK_ROOT" 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
    if [ $? -ne 0 ]; then
        log_warning "インストール済みパッケージの確認に問題があります"
        return 1
    fi
    
    # 全てのコンポーネントの確認
    for component in "${SDK_COMPONENTS[@]}"; do
        if echo "$INSTALLED_PACKAGES" | grep -q "$component"; then
            log_success "$component は正しくインストールされています"
        else
            log_error "$component がインストールされていません"
            ((missing_components++))
        fi
    done
    
    if [ $missing_components -gt 0 ]; then
        log_error "$missing_components 個のコンポーネントがインストールされていません"
        return 1
    else
        log_success "すべてのコンポーネントがインストールされています"
        return 0
    fi
} 