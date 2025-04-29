#!/bin/bash

# スクリプト自身の場所を絶対パスで取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# 環境のルートディレクトリは外部から渡されたREPO_ROOTを利用

# デバッグモードの時だけパス情報を表示
[ "${DEBUG:-false}" = "true" ] && echo "SCRIPT_DIR: $SCRIPT_DIR" && echo "REPO_ROOT: $REPO_ROOT"

# 共通ユーティリティを読み込み
source "$SCRIPT_DIR/../utils/logging.sh"
source "$SCRIPT_DIR/../utils/helpers.sh"

# npmパッケージのインストール関数
install_npm_package() {
    local package="$1"
    local version="$2"
    
    # すでにインストール済みかチェック
    if npm list -g "$package" &>/dev/null && [ "$version" = "latest" ]; then
        log_installed "$package"
        return 0
    elif [ "$version" != "latest" ] && npm list -g "$package" 2>/dev/null | grep -q "$package@$version"; then
        log_installed "$package" "$version"
        return 0
    fi
    
    # インストールを実行
    log_installing "$package" "$version"
    npm install -g $([[ "$IS_CI" = "true" ]] && echo "--force") $package${version:+@$version} || {
        if [ "${IS_CI:-false}" = "true" ]; then
            log_warning "$package のインストールに失敗しましたが、CI環境なので続行します"
        else
            log_error "$package のインストールに失敗しました"
            return 1
        fi
    }
    
    return 0
}

# React Nativeに必要なパッケージをインストール
install_required_packages() {
    log_info "npm パッケージを確認しています..."
    local npm_packages_file="$REPO_ROOT/node/global-packages.json"
    
    if [ ! -f "$npm_packages_file" ]; then
        log_warning "npmパッケージ定義ファイルが見つかりません: $npm_packages_file"
        install_default_packages
        return 0
    fi
    
    log_info "JSON形式のnpmパッケージリストを使います"
    
    # グローバルツールのインストール
    install_global_packages "$npm_packages_file"
    
    # React Native開発ツールのインストール
    install_rn_dev_tools "$npm_packages_file"
}

# 最低限必要なパッケージのインストール
install_default_packages() {
    log_info "最低限必要なツールだけインストールします"
    install_npm_package "yarn" "latest"
    install_npm_package "react-native-cli" "latest"
}

# グローバルパッケージのインストール
install_global_packages() {
    local npm_packages_file="$1"
    
    log_info "基本的なグローバルツールを確認中..."
    local global_packages=$(cat "$npm_packages_file" | grep -o '"globalPackages":{[^}]*}' | sed 's/"globalPackages"://')
    
    if [ -n "$global_packages" ]; then
        # JSONからパッケージ名を取り出す
        echo "$global_packages" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
            local version=$(echo "$global_packages" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
            install_npm_package "$package" "$version"
        done
    fi
}

# React Native開発ツールのインストール
install_rn_dev_tools() {
    local npm_packages_file="$1"
    
    log_info "React Native開発ツールを確認中..."
    local rn_tools=$(cat "$npm_packages_file" | grep -o '"reactNativeDevTools":{[^}]*}' | sed 's/"reactNativeDevTools"://')
    
    if [ -n "$rn_tools" ]; then
        # JSONからパッケージ名を取り出す
        echo "$rn_tools" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
            local version=$(echo "$rn_tools" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
            install_npm_package "$package" "$version"
        done
    fi
}

# Xcodeを検出
detect_xcode() {
    log_info "iOS開発環境を確認中..."
    
    # CI環境では飛ばす
    if [ "${IS_CI:-false}" = "true" ]; then
        log_info "CI環境なのでXcodeの確認はスキップします"
        return 0
    fi
    
    # xcodebuildコマンドがあるか
    if command_exists "xcodebuild"; then
        log_success "Xcode が見つかりました: $(xcodebuild -version | head -n1) ✓"
        return 0
    fi
    
    # 一般的な場所を探す
    if [ -d "/Applications/Xcode.app" ] || [ -d "/Applications/Xcode-beta.app" ] || ls -d /Applications/Xcode*.app &>/dev/null; then
        log_success "Xcode がApplicationsフォルダにありました ✓"
        return 0
    fi
    
    log_warning "Xcode が見つかりません。iOS開発にはXcodeが必要です。"
}

# React Native環境の診断
run_rn_doctor_check() {
    # CI環境では飛ばす
    if [ "${IS_CI:-false}" = "true" ]; then
        log_info "CI環境なので環境診断はスキップします"
        return 0
    fi
    
    log_info "React Native環境診断を実行します..."
    
    # 診断コマンドを選択
    local doctor_cmd
    if npm list -g @react-native-community/cli >/dev/null 2>&1; then
        doctor_cmd="react-native doctor"
    else
        doctor_cmd="npx --yes @react-native-community/cli doctor"
    fi
    
    # 診断実行
    $doctor_cmd || log_warning "診断で警告やエラーが出ましたが、セットアップは続行します"
    log_info "React Native環境診断が終わりました"
}

# 必要なコマンドがあるか確認
verify_required_commands() {
    # Node.jsがあるか確認（必須）
    if ! command_exists "node"; then
        handle_error "Node.js がインストールされていません。Brewfileに入れておくべきです。"
    fi
    log_info "Node.js バージョン: $(node -v)"
    
    # 主要コンポーネントのチェック
    for cmd in "watchman" "java" "pod"; do
        if ! command_exists "$cmd"; then
            log_warning "$cmd がインストールされていません${IS_CI:+。CI環境では問題ありません}"
            continue
        fi
        
        log_success "$cmd がインストールされています ✓"
        
        # バージョン表示（CI環境では省略）
        if [ "${IS_CI:-false}" != "true" ]; then
            case "$cmd" in
                java) java -version 2>&1 | head -n1 ;;
                pod) pod --version ;;
            esac
        fi
    done
}

# Android SDKを確認
check_android_sdk() {
    log_info "Android SDK を確認中..."
    if [ -d "$HOME/Library/Android/sdk" ]; then
        log_success "Android SDK が見つかりました ✓"
    else
        log_warning "Android SDK が見つかりません${IS_CI:+。CI環境では問題ありません}"
    fi
}

# メイン関数: React Native環境のセットアップ
setup_reactnative() {
    log_start "React Native 環境のセットアップを始めます..."

    # 必要なコマンドの確認
    verify_required_commands
    
    # 必要なパッケージのインストール
    install_required_packages
    
    # Android SDKの確認
    check_android_sdk

    # Xcodeの検出
    detect_xcode
    
    # React Native環境診断の実行
    run_rn_doctor_check
    
    # セットアップ完了
    log_success "React Native 環境のセットアップが完了しました！"
    if [ "${IS_CI:-false}" != "true" ]; then
        log_info "新しいプロジェクト作成: npx react-native init MyApp"
        log_info "プロジェクト実行: cd MyApp && npx react-native run-ios/android"
    fi
}

# 簡易的な環境検証
verify_reactnative_setup() {
    log_start "React Native環境を検証中..."
    local verification_failed=false
    
    # 主要コマンドがあるかチェック
    verify_core_commands
    
    # 設定ファイルの確認
    verify_config_files
    
    # 検証結果
    if [ "$verification_failed" = "true" ] && [ "${IS_CI:-false}" != "true" ]; then
        log_error "React Native環境の検証に失敗しました"
        return 1
    else
        log_success "React Native環境の検証が完了しました"
        return 0
    fi
}

# 主要コマンドの検証
verify_core_commands() {
    for cmd in "node" "npm" "watchman"; do
        if ! command_exists "$cmd"; then
            if [ "${IS_CI:-false}" = "true" ]; then
                log_warning "${cmd}コマンドが見つかりませんが、CI環境なので続行します"
            else
                log_error "${cmd}コマンドが見つかりません"
                verification_failed=true
            fi
        else
            log_success "${cmd}がインストールされています: $($cmd --version 2>/dev/null || echo 'バージョン不明')"
        fi
    done
    
    # 追加コマンドのチェック
    if command_exists "yarn"; then
        log_success "yarnがインストールされています: $(yarn -v)"
    fi
}

# 設定ファイルの検証
verify_config_files() {
    [ -f "$REPO_ROOT/node/global-packages.json" ] && log_success "global-packages.jsonが存在します" || log_warning "global-packages.jsonが見つかりません"
}

# スクリプトの実行開始点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # CI環境用の設定
    if [ "${IS_CI:-false}" = "true" ]; then
        # CI環境ではエラーがあっても続行
        set +e
        
        # Homebrewの自動更新を無効に
        export HOMEBREW_NO_AUTO_UPDATE=1
    fi

    # コマンド実行
    case "${1:-setup}" in
        doctor|diagnosis|check) run_rn_doctor_check ;;
        verify) verify_reactnative_setup ;;
        *) setup_reactnative ;;
    esac
fi