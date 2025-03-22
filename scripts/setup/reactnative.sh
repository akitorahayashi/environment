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
    
    # npmパッケージがすでにインストールされているか確認
    if npm list -g "$package" &>/dev/null && [ "$version" = "latest" ]; then
        log_success "$package はすでにインストールされています ✓"
        return 0
    elif [ "$version" != "latest" ] && npm list -g "$package" 2>/dev/null | grep -q "$package@$version"; then
        log_success "$package@$version はすでにインストールされています ✓"
        return 0
    fi
    
    # インストール実行
    log_info "${version}版の$package をインストール中..."
    npm install -g $([[ "$IS_CI" = "true" ]] && echo "--force") $package${version:+@$version} || {
        if [ "${IS_CI:-false}" = "true" ]; then
            log_warning "$package のインストールに失敗しましたが、CI環境では続行します"
        else
            log_error "$package のインストールに失敗しました"
            return 1
        fi
    }
    
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
            # JSONからパッケージ名を抽出
            echo "$global_packages" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
                version=$(echo "$global_packages" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                install_npm_package "$package" "$version"
            done
        fi
        
        # React Native開発ツールのインストール
        log_info "React Native開発ツールを確認しています..."
        rn_tools=$(cat "$npm_packages_file" | grep -o '"reactNativeDevTools":{[^}]*}' | sed 's/"reactNativeDevTools"://')
        
        if [ -n "$rn_tools" ]; then
            # JSONからパッケージ名を抽出
            echo "$rn_tools" | grep -o '"[^"]*":' | sed 's/[":]//g' | while read -r package; do
                version=$(echo "$rn_tools" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                install_npm_package "$package" "$version"
            done
        fi
    else
        log_warning "npmパッケージ定義ファイルが見つかりません: $npm_packages_file"
        # 最小限のツールセットをインストール
        install_npm_package "yarn" "latest"
        install_npm_package "react-native-cli" "latest"
    fi
}

# ステップ2: Xcodeの検出
detect_xcode() {
    log_info "iOS開発環境を確認中..."
    
    # CI環境ではスキップ
    if [ "${IS_CI:-false}" = "true" ]; then
        log_info "CI環境: Xcodeの確認をスキップします"
        return 0
    fi
    
    # xcodebuildコマンドが存在する場合
    if command_exists "xcodebuild"; then
        log_success "Xcode が見つかりました: $(xcodebuild -version | head -n1) ✓"
        return 0
    fi
    
    # 標準パスでチェック
    if [ -d "/Applications/Xcode.app" ] || [ -d "/Applications/Xcode-beta.app" ] || ls -d /Applications/Xcode*.app &>/dev/null; then
        log_success "Xcode が Applications フォルダに見つかりました ✓"
        return 0
    fi
    
    log_warning "Xcode が見つかりません。React Native の iOS 開発には Xcode が必要です。"
}

# ステップ3: React Native環境診断
run_rn_doctor_check() {
    # CI環境ではスキップ
    if [ "${IS_CI:-false}" = "true" ]; then
        log_info "CI環境: 環境診断をスキップします"
        return 0
    fi
    
    log_info "React Native環境診断を実行します..."
    
    # 診断コマンド選択
    local doctor_cmd
    if npm list -g @react-native-community/cli >/dev/null 2>&1; then
        doctor_cmd="react-native doctor"
    else
        doctor_cmd="npx --yes @react-native-community/cli doctor"
    fi
    
    # 診断実行
    $doctor_cmd || log_warning "診断コマンドが警告やエラーを報告しましたが、セットアップは続行します"
    log_info "React Native環境診断が完了しました"
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
            log_warning "$cmd がインストールされていません${IS_CI:+。CI環境では許容されます}"
            continue
        fi
        
        log_success "$cmd がインストールされています ✓"
        
        # バージョン表示（CI環境は省略可能）
        if [ "${IS_CI:-false}" != "true" ]; then
            case "$cmd" in
                java) java -version 2>&1 | head -n1 ;;
                pod) pod --version ;;
            esac
        fi
    done
    
    # Android SDK チェック
    log_info "Android SDK の確認中..."
    if [ -d "$HOME/Library/Android/sdk" ]; then
        log_success "Android SDK が存在しています ✓"
    else
        log_warning "Android SDK が見つかりません${IS_CI:+。CI環境では許容されます}"
    fi

    # Xcodeの検出
    detect_xcode
    
    # React Native環境診断の実行
    run_rn_doctor_check
    
    # セットアップ完了
    log_success "React Native 環境のセットアップが完了しました！"
    if [ "${IS_CI:-false}" != "true" ]; then
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
            if [ "${IS_CI:-false}" = "true" ]; then
                log_warning "${cmd}コマンドが見つかりませんが、CI環境では続行します"
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
    
    # 設定ファイルの確認
    [ -f "$ROOT_DIR/config/global-packages.json" ] && log_success "global-packages.jsonが存在します" || log_warning "global-packages.jsonが見つかりません"
    
    # 検証結果
    if [ "$verification_failed" = "true" ] && [ "${IS_CI:-false}" != "true" ]; then
        log_error "React Native環境の検証に失敗しました"
        return 1
    else
        log_success "React Native環境の検証が完了しました"
        return 0
    fi
}

# スクリプトのエントリーポイント
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # CI環境用の基本設定
    if [ "${IS_CI:-false}" = "true" ]; then
        # CI環境では常に成功するようにする
        set +e
        
        # Homebrewの自動更新を無効化
        export HOMEBREW_NO_AUTO_UPDATE=1
    fi

    # コマンド実行
    case "${1:-setup}" in
        doctor|diagnosis|check) run_rn_doctor_check ;;
        verify) verify_reactnative_setup ;;
        *) setup_reactnative ;;
    esac
fi