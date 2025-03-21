#!/bin/bash

# React Native セットアップスクリプト

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

# ユーティリティのロード
source "$ROOT_DIR/scripts/utils/logging.sh"
source "$ROOT_DIR/scripts/utils/helpers.sh"

# React Native CLI のインストール確認と実行
setup_reactnative() {
    log_start "React Native 環境のセットアップを開始します..."

    # Node.js と npm の確認
    if ! command_exists "node"; then
        log_error "Node.js がインストールされていません。Brewfile に追加されているはずです。"
        return 1
    fi

    # Node.js バージョン確認
    node_version=$(node -v)
    log_info "Node.js バージョン: $node_version"

    # JSONパッケージ定義ファイルからインストール
    log_info "npm パッケージをインストールしています..."
    npm_packages_file="$ROOT_DIR/config/global-packages.json"
    
    if [ -f "$npm_packages_file" ]; then
        log_info "JSON形式のnpmパッケージリストを使用します"
        
        # グローバルツールのインストール
        log_info "基本的なグローバルツールをインストールしています..."
        global_packages=$(cat "$npm_packages_file" | grep -o '"globalPackages":{[^}]*}' | sed 's/"globalPackages"://')
        
        if [ -n "$global_packages" ]; then
            # JSONからパッケージ名を抽出
            package_names=$(echo "$global_packages" | grep -o '"[^"]*":' | sed 's/[":]//g')
            
            for package in $package_names; do
                # パッケージがインストール済みかを確認
                if npm list -g "$package" >/dev/null 2>&1; then
                    log_info "$package はすでにインストールされています ✓"
                else
                    # バージョン指定を取得
                    version=$(echo "$global_packages" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                    
                    if [ "$version" = "latest" ]; then
                        log_info "$package をインストールしています..."
                        # CI環境では--forceフラグを追加
                        if [ "$IS_CI" = "true" ]; then
                            npm install -g --force "$package" || log_warning "$package のインストールに失敗しました"
                        else
                            npm install -g "$package" || log_warning "$package のインストールに失敗しました"
                        fi
                    else
                        log_info "$package@$version をインストールしています..."
                        if [ "$IS_CI" = "true" ]; then
                            npm install -g --force "$package@$version" || log_warning "$package@$version のインストールに失敗しました"
                        else
                            npm install -g "$package@$version" || log_warning "$package@$version のインストールに失敗しました"
                        fi
                    fi
                fi
            done
        fi
        
        # React Native開発ツールのインストール
        log_info "React Native開発ツールをインストールしています..."
        rn_tools=$(cat "$npm_packages_file" | grep -o '"reactNativeDevTools":{[^}]*}' | sed 's/"reactNativeDevTools"://')
        
        if [ -n "$rn_tools" ]; then
            # JSONからパッケージ名を抽出
            package_names=$(echo "$rn_tools" | grep -o '"[^"]*":' | sed 's/[":]//g')
            
            for package in $package_names; do
                # パッケージがインストール済みかを確認
                if npm list -g "$package" >/dev/null 2>&1; then
                    log_info "$package はすでにインストールされています ✓"
                else
                    # バージョン指定を取得
                    version=$(echo "$rn_tools" | grep -o "\"$package\":\"[^\"]*\"" | sed "s/\"$package\":\"//" | sed 's/"//g')
                    
                    if [ "$version" = "latest" ]; then
                        log_info "$package をインストールしています..."
                        if [ "$IS_CI" = "true" ]; then
                            npm install -g --force "$package" || log_warning "$package のインストールに失敗しました"
                        else
                            npm install -g "$package" || log_warning "$package のインストールに失敗しました"
                        fi
                    else
                        log_info "$package@$version をインストールしています..."
                        if [ "$IS_CI" = "true" ]; then
                            npm install -g --force "$package@$version" || log_warning "$package@$version のインストールに失敗しました"
                        else
                            npm install -g "$package@$version" || log_warning "$package@$version のインストールに失敗しました"
                        fi
                    fi
                fi
            done
        fi
    else
        log_error "npmパッケージ定義ファイルが見つかりません: $npm_packages_file"
        log_info "基本的なnpmパッケージをインストールします..."
        
        # 最小限のツールセットをインストール（フォールバック）
        if ! npm list -g yarn >/dev/null 2>&1; then
            log_info "Yarn をインストールしています..."
            if [ "$IS_CI" = "true" ]; then
                npm install -g --force yarn
            else
                npm install -g yarn
            fi
        else
            log_info "Yarn はすでにインストールされています ✓"
        fi
        
        if ! npm list -g react-native-cli >/dev/null 2>&1; then
            log_info "React Native CLI をインストールしています..."
            if [ "$IS_CI" = "true" ]; then
                npm install -g --force react-native-cli
            else
                npm install -g react-native-cli
            fi
        else
            log_info "React Native CLI はすでにインストールされています ✓"
        fi
    fi

    # Watchman のインストール確認（効率的なファイル監視用）
    if ! command_exists "watchman"; then
        # CI環境ではエラーではなく警告に
        if [ "$IS_CI" = "true" ]; then
            log_warning "Watchman がインストールされていません。CI環境では許容されます。"
        else
            log_error "Watchman がインストールされていません。Brewfile に追加されているはずです。"
        fi
    else
        log_info "Watchman がインストールされています ✓"
    fi

    # JDK がインストールされているか確認
    if ! command_exists "java"; then
        # CI環境ではエラーではなく警告に
        if [ "$IS_CI" = "true" ]; then
            log_warning "Java がインストールされていません。CI環境では許容されます。"
        else
            log_error "Java がインストールされていません。temurin は Brewfile に追加されているはずです。"
        fi
    else
        log_info "Java がインストールされています ✓"
        java -version
    fi

    # CocoaPods がインストールされているか確認
    if ! command_exists "pod"; then
        # CI環境ではエラーではなく警告に
        if [ "$IS_CI" = "true" ]; then
            log_warning "CocoaPods がインストールされていません。CI環境では許容されます。"
        else
            log_error "CocoaPods がインストールされていません。Brewfile に追加されているはずです。"
        fi
    else
        log_info "CocoaPods がインストールされています ✓"
        pod --version
    fi

    # Android SDK の確認
    log_info "Android SDK の確認中..."
    if [ -d "$HOME/Library/Android/sdk" ]; then
        log_info "Android SDK が存在しています ✓"
    else
        # CI環境ではエラーではなく警告に
        if [ "$IS_CI" = "true" ]; then
            log_warning "Android SDK が見つかりません。CI環境では許容されます。"
        else
            log_warning "Android SDK が見つかりません。Android Studio を起動して SDK をインストールする必要があります。"
        fi
    fi

    # iOS Simulator の確認
    log_info "iOS Simulator の確認中..."
    
    # Xcodeの検出方法を改善（xcodesツールを優先的に使用）
    XCODE_FOUND=false
    
    # 方法1: xcodesコマンドでインストール済みのXcodeを確認（優先）
    if command_exists "xcodes"; then
        log_info "xcodesツールを使用してXcodeを検出します..."
        
        # インストール済みのXcodeバージョン一覧を取得
        INSTALLED_XCODES=$(xcodes installed 2>/dev/null || echo "")
        if [ -n "$INSTALLED_XCODES" ]; then
            XCODE_COUNT=$(echo "$INSTALLED_XCODES" | grep -c "Xcode" || echo "0")
            if [ "$XCODE_COUNT" -gt 0 ]; then
                log_info "xcodes でインストールされた Xcode が $XCODE_COUNT 個見つかりました ✓"
                XCODE_FOUND=true
                
                # 選択されているXcodeを確認（インストールリストから(Selected)を持つものを探す）
                SELECTED_XCODE=$(echo "$INSTALLED_XCODES" | grep "(Selected)" | head -1)
                if [ -n "$SELECTED_XCODE" ]; then
                    XCODE_VERSION=$(echo "$SELECTED_XCODE" | awk '{print $1}')
                    XCODE_PATH=$(echo "$SELECTED_XCODE" | awk '{print $NF}')
                    log_info "現在選択されているXcode: $XCODE_VERSION (パス: $XCODE_PATH) ✓"
                else
                    log_warning "選択されているXcodeが見つかりませんでした"
                    
                    # 念のためxcodes selectedも試す
                    SELECTED_XCODE=$(xcodes selected 2>/dev/null || echo "")
                    if [ -n "$SELECTED_XCODE" ]; then
                        log_info "現在選択されているXcode: $SELECTED_XCODE ✓"
                    fi
                fi
                
                # インストール済みのXcodeバージョン（最大3つまで）を表示
                echo "$INSTALLED_XCODES" | grep "Xcode" | head -3 | while read -r line; do
                    log_info "  - $line"
                done
                
                # 3つ以上ある場合は省略メッセージを表示
                if [ "$XCODE_COUNT" -gt 3 ]; then
                    log_info "  - その他 $(($XCODE_COUNT - 3)) 個のバージョン..."
                fi
            else
                log_warning "xcodesでインストールされたXcodeは見つかりませんでした"
            fi
        else
            log_warning "xcodesでインストール済みのXcode一覧を取得できませんでした"
        fi
    else
        log_warning "xcodesコマンドがインストールされていません"
    fi
    
    # 方法2: xcode-selectで選択されているXcodeを確認
    if ! $XCODE_FOUND && xcode-select -p &>/dev/null; then
        XCODE_PATH=$(xcode-select -p)
        if [[ "$XCODE_PATH" != *"CommandLineTools"* ]]; then
            log_info "Xcode が選択されています: $XCODE_PATH ✓"
            XCODE_FOUND=true
        fi
    fi
    
    # 方法3: 一般的なパスをチェック
    if ! $XCODE_FOUND; then
        if [ -d "/Applications/Xcode.app" ] || [ -d "/Applications/Xcode-beta.app" ] || ls -d /Applications/Xcode*.app &>/dev/null; then
            log_info "Xcode が Applications フォルダに見つかりました ✓"
            XCODE_FOUND=true
        fi
    fi
    
    # 方法4: mdfindでシステム全体を検索（最後の手段）
    if ! $XCODE_FOUND && command_exists "mdfind"; then
        XCODE_MDFIND=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" 2>/dev/null | head -n 1)
        if [ -n "$XCODE_MDFIND" ]; then
            log_info "Xcode がシステム上で見つかりました: $XCODE_MDFIND ✓"
            XCODE_FOUND=true
        fi
    fi
    
    # 結果を表示
    if ! $XCODE_FOUND; then
        # CI環境ではエラーではなく警告に
        if [ "$IS_CI" = "true" ]; then
            log_warning "Xcode が見つかりません。CI環境では許容されます。"
        else
            log_warning "Xcode が見つかりません。React Native の iOS 開発には Xcode が必要です。"
            log_info "xcodesツールを使用してXcodeをインストールすることをお勧めします: 'xcodes install <バージョン>'"
        fi
    fi

    # React Native環境診断を実行
    run_rn_doctor_check

    # セットアップ完了メッセージ
    log_success "React Native 環境のセットアップが完了しました！"
    if [ "$IS_CI" != "true" ]; then
        log_info "新しいプロジェクトを作成するには: npx react-native init MyApp"
        log_info "既存のプロジェクトを実行するには: cd MyApp && npx react-native run-ios/android"
    fi

    return 0
} 

# React Native環境診断を一時プロジェクトで実行
run_rn_doctor_check() {
    # CI環境ではスキップ
    if [ "$IS_CI" = "true" ]; then
        log_info "CI環境ではReact Native環境診断をスキップします"
        return 0
    fi

    log_info "React Native環境診断を実行します..."
    
    # 一時ディレクトリを作成して診断を実行
    TEMP_DIR=$(mktemp -d)
    log_info "一時診断プロジェクト作成: $TEMP_DIR"
    
    # 元のディレクトリを記憶してから一時ディレクトリに移動
    ORIG_DIR=$(pwd)
    cd "$TEMP_DIR" || { log_error "一時ディレクトリに移動できません"; return 1; }
    
    # 最小限のpackage.jsonを作成
    cat > package.json << EOF
{
  "name": "rn-environment-check",
  "private": true,
  "devDependencies": {
    "react-native": "latest",
    "@react-native-community/cli": "latest"
  }
}
EOF
    
    # パッケージ静かにインストール
    log_info "診断パッケージをインストール中..."
    npm install --silent > /dev/null 2>&1 || { 
        log_warning "診断パッケージのインストールに失敗しました"
        cd "$ORIG_DIR"
        rm -rf "$TEMP_DIR"
        return 1
    }
    
    # 診断実行（自動承認フラグ付き）
    npx react-native doctor --yes > /dev/null 2>&1 || log_warning "React Native環境診断に問題があります"
    
    # 後片付け
    cd "$ORIG_DIR"
    rm -rf "$TEMP_DIR"
    log_info "React Native環境診断が完了しました"
}

# React Native環境の検証
verify_reactnative_setup() {
    log_start "React Native環境を検証中..."
    local verification_failed=false
    
    # Node.jsの確認
    if ! command_exists node; then
        log_error "node.jsコマンドが見つかりません"
        verification_failed=true
    else
        log_success "node.jsがインストールされています: $(node -v)"
    fi
    
    # npm確認
    if ! command_exists npm; then
        log_error "npmコマンドが見つかりません"
        verification_failed=true
    else
        log_success "npmがインストールされています: $(npm -v)"
    fi
    
    # Yarnの確認
    if ! command_exists yarn; then
        log_warning "yarnコマンドが見つかりません"
    else
        log_success "yarnがインストールされています: $(yarn -v)"
    fi
    
    # React Native CLIの確認
    if npm list -g react-native-cli >/dev/null 2>&1; then
        log_success "react-native-cliがグローバルにインストールされています"
    else
        log_warning "react-native-cliがグローバルにインストールされていません"
        # CI環境では警告のみ
        if [ "$IS_CI" != "true" ]; then
            verification_failed=true
        fi
    fi
    
    # Watchmanの確認
    if ! command_exists watchman; then
        log_error "watchmanコマンドが見つかりません"
        verification_failed=true
    else
        log_success "watchmanがインストールされています: $(watchman --version)"
    fi
    
    # global-packages.jsonの存在確認
    if [ -f "$ROOT_DIR/config/global-packages.json" ]; then
        log_success "global-packages.jsonが存在します"
    else
        log_warning "global-packages.jsonが見つかりません"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "React Native環境の検証に失敗しました"
        return 1
    else
        log_success "React Native環境の検証が完了しました"
        return 0
    fi
}