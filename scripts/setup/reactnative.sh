#!/bin/bash

# React Native セットアップスクリプト

# 現在のスクリプトディレクトリを取得（絶対パスを使用）
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 環境ディレクトリを取得（2つ上の階層）
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

# デバッグモードの場合のみパスを出力
[ "${DEBUG:-false}" = "true" ] && echo "SCRIPT_DIR: $SCRIPT_DIR" && echo "ROOT_DIR: $ROOT_DIR"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/helpers.sh"

# パッケージインストール関数
install_npm_package() {
    local package="$1"
    local version="$2"
    
    # バージョン指定があるかチェック
    if [ "$version" = "latest" ]; then
        # latest指定の場合はパッケージ名だけで確認
        if npm list -g "$package" >/dev/null 2>&1; then
            log_success "$package はすでにインストールされています ✓"
            return 0
        fi
    else
        # バージョン指定がある場合
        if npm list -g "$package" 2>/dev/null | grep -q "$package@$version"; then
            log_success "$package@$version はすでにインストールされています ✓"
            return 0
        fi
    fi
    
    # インストールが必要な場合
    if [ "$version" = "latest" ]; then
        log_info "$package をインストールしています..."
        npm install -g $([[ "$IS_CI" = "true" ]] && echo "--force") "$package" || {
            log_warning "$package のインストールに失敗しました"
            return 1
        }
    else
        log_info "$package@$version をインストールしています..."
        npm install -g $([[ "$IS_CI" = "true" ]] && echo "--force") "$package@$version" || {
            log_warning "$package@$version のインストールに失敗しました"
            return 1
        }
    fi
    
    return 0
}

# ステップ1: React Nativeに必要なパッケージのインストール
install_required_packages() {
    log_info "npm パッケージを確認しています..."
    npm_packages_file="$ROOT_DIR/config/global-packages.json"
    
    if [ -f "$npm_packages_file" ]; then
        log_info "JSON形式のnpmパッケージリストを使用します"
        
        # グローバルツールのインストール
        log_info "基本的なグローバルツールを確認しています..."
        global_packages=$(cat "$npm_packages_file" | grep -o '"globalPackages":{[^}]*}' | sed 's/"globalPackages"://')
        
        if [ -n "$global_packages" ]; then
            # JSONからパッケージ名を抽出して処理
            echo "$global_packages" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
                version=$(echo "$global_packages" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                install_npm_package "$package" "$version"
            done
        fi
        
        # React Native開発ツールのインストール
        log_info "React Native開発ツールを確認しています..."
        rn_tools=$(cat "$npm_packages_file" | grep -o '"reactNativeDevTools":{[^}]*}' | sed 's/"reactNativeDevTools"://')
        
        if [ -n "$rn_tools" ]; then
            # JSONからパッケージ名を抽出して処理
            echo "$rn_tools" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
                version=$(echo "$rn_tools" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                install_npm_package "$package" "$version"
            done
        fi
    else
        log_warning "npmパッケージ定義ファイルが見つかりません: $npm_packages_file"
        log_info "基本的なnpmパッケージを確認します..."
        
        # 最小限のツールセットをインストール（フォールバック）
        install_npm_package "yarn" "latest"
        install_npm_package "react-native-cli" "latest"
    fi
}

# ステップ2: Xcodeの検出
detect_xcode() {
    log_info "iOS開発環境を確認中..."
    XCODE_FOUND=false
    
    # xcodesコマンドで確認（優先）
    if command_exists "xcodes" && INSTALLED_XCODES=$(xcodes installed 2>/dev/null); then
        XCODE_COUNT=$(echo "$INSTALLED_XCODES" | grep -c "Xcode" || echo "0")
        if [ "$XCODE_COUNT" -gt 0 ]; then
            log_success "xcodes でインストールされた Xcode が $XCODE_COUNT 個見つかりました ✓"
            XCODE_FOUND=true
            
            # 選択されているXcodeを確認
            SELECTED_XCODE=$(echo "$INSTALLED_XCODES" | grep "(Selected)" | head -1)
            if [ -n "$SELECTED_XCODE" ]; then
                log_success "現在選択されているXcode: $(echo "$SELECTED_XCODE" | awk '{print $1}') ✓"
            elif SELECTED_XCODE=$(xcodes selected 2>/dev/null); then
                log_success "現在選択されているXcode: $SELECTED_XCODE ✓"
            fi
        fi
    elif ! $XCODE_FOUND && xcode-select -p &>/dev/null; then
        # xcode-selectで確認
        XCODE_PATH=$(xcode-select -p)
        if [[ "$XCODE_PATH" != *"CommandLineTools"* ]]; then
            log_success "Xcode が選択されています: $XCODE_PATH ✓"
            XCODE_FOUND=true
        fi
    elif ! $XCODE_FOUND && { [ -d "/Applications/Xcode.app" ] || [ -d "/Applications/Xcode-beta.app" ] || ls -d /Applications/Xcode*.app &>/dev/null; }; then
        # 標準的なパスで確認
        log_success "Xcode が Applications フォルダに見つかりました ✓"
        XCODE_FOUND=true
    fi
    
    # Xcodeが見つからない場合
    if ! $XCODE_FOUND; then
        if [ "$IS_CI" = "true" ]; then
            log_warning "Xcode が見つかりません。CI環境では許容されます。"
        else
            log_warning "Xcode が見つかりません。React Native の iOS 開発には Xcode が必要です。"
            log_info "xcodesツールでインストール: 'xcodes install <バージョン>'"
        fi
    fi
}

# ステップ3: React Native環境診断
run_rn_doctor_check() {
    # CI環境ではスキップ
    [ "$IS_CI" = "true" ] && { log_info "CI環境では診断をスキップします"; return 0; }
    
    log_info "React Native環境診断を実行します..."
    echo "診断中に応答がない場合は、Enterキーを押してください"
    
    # 診断コマンド実行
    if npm list -g @react-native-community/cli >/dev/null 2>&1; then
        log_info "グローバルインストールされたCLIを使用します"
        DOCTOR_CMD="react-native doctor"
    else
        log_info "npxを使って診断を実行します"
        DOCTOR_CMD="npx --yes @react-native-community/cli doctor"
    fi
    
    # 診断実行（タイムアウト付き）
    DOCTOR_OUTPUT=$(timeout 30 $DOCTOR_CMD 2>&1) || {
        EXIT_CODE=$?
        handle_doctor_result "$DOCTOR_OUTPUT" $EXIT_CODE
    }
    
    # 診断結果の処理
    handle_doctor_result "$DOCTOR_OUTPUT" 0
    
    log_info "React Native環境診断が完了しました"
}

# 診断結果の処理を行う関数
handle_doctor_result() {
    local output="$1"
    local exit_code="$2"
    
    # タイムアウト処理
    if [ "$exit_code" -eq 124 ]; then
        log_warning "診断がタイムアウトしました。Android環境がないか、応答が遅いです"
        log_info "iOS開発のみを行う場合は問題ありません"
        return 0
    fi
    
    # 診断結果のサマリー表示
    if echo "$output" | grep -q "✓ All specified checks passed"; then
        log_success "すべての診断チェックが正常に完了しました"
        return 0
    fi
    
    # 警告とエラーの処理
    WARNING_COUNT=$(echo "$output" | grep -c "⚠" | tr -d '\n' || echo "0")
    ERROR_COUNT=$(echo "$output" | grep -c "✖" | tr -d '\n' || echo "0")
    
    # エラー表示
    if [ "$ERROR_COUNT" -gt 0 ]; then
        log_warning "診断で $ERROR_COUNT 個のエラーが見つかりました："
        
        # Android関連エラーかチェック
        if echo "$output" | grep -A 1 "✖" | grep -qE "Android|adb|SDK|JDK|Gradle"; then
            log_info "Android関連エラーです。Android Studioで設定可能です"
            log_info "iOS開発のみを行う場合は無視できます"
        fi
        
        # エラー内容を表示（最大10行）
        echo "$output" | grep -A 1 "✖" | head -10
    fi
    
    # 警告表示
    if [ "$WARNING_COUNT" -gt 0 ]; then
        log_warning "診断で $WARNING_COUNT 個の警告があります："
        echo "$output" | grep -A 1 "⚠" | head -10
    fi
    
    log_info "診断でエラーや警告が検出されましたが、セットアップは続行します"
}

# メイン関数: React Native環境セットアップ
setup_reactnative() {
    log_start "React Native 環境のセットアップを開始します..."

    # Node.jsの確認（必須）
    if ! command_exists "node"; then
        handle_error "Node.js がインストールされていません。Brewfile に追加されているはずです。"
    fi
    log_info "Node.js バージョン: $(node -v)"
    
    # 必要なパッケージのインストール
    install_required_packages
    
    # 主要コンポーネントのチェック
    for cmd in "watchman" "java" "pod"; do
        if ! command_exists "$cmd"; then
            if [ "$IS_CI" = "true" ]; then
                log_warning "$cmd がインストールされていません。CI環境では許容されます。"
            else
                log_warning "$cmd がインストールされていません。Brewfile に追加されているはずです。"
            fi
        else
            log_success "$cmd がインストールされています ✓"
            [ "$cmd" = "java" ] && java -version
            [ "$cmd" = "pod" ] && pod --version
        fi
    done
    
    # Android SDK チェック
    log_info "Android SDK の確認中..."
    if [ -d "$HOME/Library/Android/sdk" ]; then
        log_success "Android SDK が存在しています ✓"
    else
        if [ "$IS_CI" = "true" ]; then
            log_warning "Android SDK が見つかりません。CI環境では許容されます。"
        else
            log_warning "Android SDK が見つかりません。Android Studio 起動でインストールできます"
        fi
    fi

    # Xcodeの検出
    detect_xcode
    
    # React Native環境診断の実行
    run_rn_doctor_check
    
    # セットアップ完了
    log_success "React Native 環境のセットアップが完了しました！"
    if [ "$IS_CI" != "true" ]; then
        log_info "新しいプロジェクト作成: npx react-native init MyApp"
        log_info "既存プロジェクト実行: cd MyApp && npx react-native run-ios/android"
    fi
}

# 簡略化した環境検証
verify_reactnative_setup() {
    log_start "React Native環境を検証中..."
    local verification_failed=false
    
    # 主要コマンドの確認
    for cmd in "node" "npm" "watchman"; do
        if ! command_exists "$cmd"; then
            log_error "${cmd}コマンドが見つかりません"
            verification_failed=true
        else
            log_success "${cmd}がインストールされています: $($cmd --version 2>/dev/null || echo 'バージョン不明')"
        fi
    done
    
    # 追加コマンドのチェック
    command_exists "yarn" && log_success "yarnがインストールされています: $(yarn -v)" || log_warning "yarnコマンドが見つかりません"
    npm list -g react-native-cli >/dev/null 2>&1 && log_success "react-native-cliがインストールされています" || log_warning "react-native-cliがインストールされていません"
    
    # 設定ファイルの確認
    [ -f "$ROOT_DIR/config/global-packages.json" ] && log_success "global-packages.jsonが存在します" || log_warning "global-packages.jsonが見つかりません"
    
    # 検証結果
    if [ "$verification_failed" = "true" ]; then
        log_error "React Native環境の検証に失敗しました"
        return 1
    else
        log_success "React Native環境の検証が完了しました"
        return 0
    fi
}

# スクリプトのエントリーポイント
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-setup}" in
    doctor|diagnosis|check) run_rn_doctor_check ;;
    verify) verify_reactnative_setup ;;
    *) setup_reactnative ;;
  esac
fi