#!/bin/bash

# CI環境かどうかを検出
IS_CI=${CI:-false}

# エラー発生時に即座に終了する設定
set -e

start_time=$(date +%s)
echo "Macをセットアップ中..."

# リポジトリのルートディレクトリを設定
if [ "$IS_CI" = "true" ] && [ -n "$GITHUB_WORKSPACE" ]; then
    REPO_ROOT="$GITHUB_WORKSPACE"
else
    REPO_ROOT="$HOME/environment"
fi

# メイン実行部分 - スクリプト全体の流れを把握しやすくするため先頭に配置
main() {
    # 各セットアップステップの実行
    install_rosetta        # Apple M1, M2 向けに Rosetta 2 をインストール
    install_homebrew       # Homebrew をインストール
    setup_shell_config     # zsh の設定を適用
    setup_git_config       # Git の設定と gitignore_global を適用
    setup_ssh_agent        # SSH キーのエージェントを設定
    setup_github_cli       # GitHub CLIのセットアップ
    setup_mac_settings     # Mac のシステム設定を復元
    install_brewfile       # Brewfile のパッケージをインストール

    # Xcodeのインストールを実行
    log_start "Xcodeのインストールを開始します..."
    if ! install_xcode; then
        handle_error "Xcodeのインストールに問題がありました"
    else
        log_success "Xcodeのインストールが完了しました"
    fi

    # Xcodeに依存するものをインストール
    setup_flutter          # Flutter の開発環境をセットアップ
    setup_cursor           # Cursorのセットアップ

    # インストール結果の表示
    end_time=$(date +%s)
    elapsed_time=$((end_time - start_time))

    # 実行完了メッセージ
    log_success "すべてのインストールと設定が完了しました！"
    log_success "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"

    # 新しいシェルセッションを開始
    exec $SHELL -l
}

# ログ出力
log_info() {
    echo "ℹ️ $1"
}

log_success() {
    echo "✅ $1"
}

log_warning() {
    echo "⚠️ $1"
}

log_error() {
    echo "❌ $1"
}

log_start() {
    echo "🔄 $1"
}

# エラーを処理する
handle_error() {
    log_error "$1"
    log_error "スクリプトを終了します。"
    exit 1
}


# パスワードプロンプトを表示する
prompt_for_sudo() {
    local reason="$1"
    echo ""
    echo "⚠️ 管理者権限が必要な操作を行います: $reason"
    echo "🔒 Macロック解除時のパスワードを入力してください"
    echo ""
} 

# コマンドが存在するかチェックする
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# シンボリックリンクを安全に作成する関数
create_symlink() {
    local source_file="$1"
    local target_file="$2"
    
    # ソースファイルが存在するか確認
    if [ ! -f "$source_file" ] && [ ! -d "$source_file" ]; then
        handle_error "$source_file が見つかりません"
    fi
    
    # 既存のファイルやシンボリックリンクが存在する場合は削除
    if [ -L "$target_file" ] || [ -f "$target_file" ] || [ -d "$target_file" ]; then
        rm -rf "$target_file"
    fi
    
    # シンボリックリンクを作成
    ln -sf "$source_file" "$target_file"
    log_success "$(basename "$target_file") のシンボリックリンクを作成しました"
}

# Apple M1, M2 向け Rosetta 2 のインストール
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Mac のチップモデルを取得
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        log_info " 🖥  Mac Model: $MAC_MODEL"

        # M1 または M2 の場合のみ Rosetta 2 をインストール
        if [[ "$MAC_MODEL" == *"M1"* || "$MAC_MODEL" == *"M2"* ]]; then
            # すでに Rosetta 2 がインストールされているかチェック
            if pgrep oahd >/dev/null 2>&1; then
                log_success "Rosetta 2 はすでにインストール済み"
                return
            fi

            # Rosetta 2 をインストール
            log_start "Rosetta 2 を $MAC_MODEL 向けにインストール中..."
            if [ "$IS_CI" = "true" ]; then
                # CI環境では非対話型でインストール
                softwareupdate --install-rosetta --agree-to-license || true
            else
                softwareupdate --install-rosetta --agree-to-license
            fi

            # インストールの成否をチェック
            if pgrep oahd >/dev/null 2>&1; then
                log_success "Rosetta 2 のインストールが完了しました"
            else
                handle_error "Rosetta 2 のインストールに失敗しました"
            fi
        else
            log_success "この Mac ($MAC_MODEL) には Rosetta 2 は不要"
        fi
    else
        log_success "この Mac は Apple Silicon ではないため、Rosetta 2 は不要"
    fi
}

install_homebrew() {
    if ! command_exists brew; then
        log_start "Homebrew をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            log_info "CI環境では非対話型でインストールします"
            # CI環境では非対話型でインストール
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # インストールの結果を確認
        if ! command_exists brew; then
            handle_error "Homebrewのインストールに失敗しました"
        fi
        
        # Homebrew PATH設定を即時有効化
        if [[ "$(uname -m)" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        log_success "Homebrew のインストール完了"
    else
        log_success "Homebrew はすでにインストール済み"
    fi
}

setup_shell_config() {
    log_start "シェルの設定を適用中..."
    
    # ディレクトリとファイルの存在確認
    if [[ ! -d "$REPO_ROOT/shell" ]]; then
        handle_error "$REPO_ROOT/shell ディレクトリが見つかりません"
    fi
    
    if [[ ! -f "$REPO_ROOT/shell/.zprofile" ]]; then
        handle_error "$REPO_ROOT/shell/.zprofile ファイルが見つかりません"
    fi
    
    # .zprofileファイルのシンボリックリンクを作成
    create_symlink "$REPO_ROOT/shell/.zprofile" "$HOME/.zprofile"
    
    # 設定を反映（CI環境ではスキップ）
    if [ "$IS_CI" != "true" ] && [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi
    
    log_success "シェルの設定を適用完了"
}

# Git の設定を適用
setup_git_config() {
    log_start "Git の設定を適用中..."
    
    # シンボリックリンクを作成
    create_symlink "$REPO_ROOT/git/.gitconfig" "$HOME/.gitconfig"
    create_symlink "$REPO_ROOT/git/.gitignore_global" "$HOME/.gitignore_global"
    
    git config --global core.excludesfile "$HOME/.gitignore_global"
    log_success "Git の設定を適用完了"
}

# Brewfile に記載されているパッケージをインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/config/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        handle_error "$brewfile_path が見つかりません"
    fi

    log_start "Homebrew パッケージのインストールを開始します..."

    # GitHub認証の設定 (CI環境用)
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        log_info "🔑 CI環境用のGitHub認証を設定中..."
        # 認証情報を環境変数に設定
        export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN_CI"
        # Gitの認証設定
        git config --global url."https://${GITHUB_ACTOR:-github-actions}:${GITHUB_TOKEN_CI}@github.com/".insteadOf "https://github.com/"
    fi

    # パッケージをインストール
    if ! brew bundle --file "$brewfile_path"; then
        handle_error "Brewfileからのパッケージインストールに失敗しました"
    else
        log_success "Homebrew パッケージのインストールが完了しました"
    fi
    
    # 重要なパッケージが正しくインストールされているか確認
    check_critical_packages
}

# 重要なパッケージの存在確認
check_critical_packages() {
    log_start "重要なパッケージの確認中..."
    
    CRITICAL_PACKAGES=("flutter" "android-commandlinetools" "temurin")
    for package in "${CRITICAL_PACKAGES[@]}"; do
        if ! brew list --cask "$package" &>/dev/null; then
            handle_error "重要なパッケージ '$package' が見つかりません"
        fi
        log_success "$package が正常にインストールされています"
    done
}

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
        yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses > /dev/null 2>&1 || log_warning "Android SDK ライセンスへの同意に一部問題がありました"
        yes | flutter doctor --android-licenses || log_warning "Flutter Android ライセンスへの同意に一部問題がありました"
        log_success "Android SDK ライセンスに同意しました"
    else
        # ライセンス同意状態を確認
        if ! flutter doctor | grep -q "Some Android licenses not accepted"; then
            log_success "Android SDK ライセンスはすでに同意済みです"
        else
            log_info "Android SDK ライセンスへの同意が必要です"
            if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
                # sdkmanager ライセンスに同意（エラー処理を改善）
                {
                    yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses 
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
    INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
    
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
        if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" "$component" > /dev/null; then
            log_success "$component のインストールが完了しました"
        else
            log_warning "$component のインストールに失敗しました"
            
            # CI環境での特別な処理
            if [ "$IS_CI" = "true" ]; then
                log_info "CI環境での代替インストールを試みます..."
                # 代替のインストール方法を試す
                if echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --install "$component" > /dev/null; then
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
    "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list > /dev/null
    if [ $? -eq 0 ]; then
        log_success "Android SDK コンポーネントの確認が完了しました"
    else
        log_warning "インストール結果の確認に失敗しましたが、続行します"
    fi
}

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

# Cursor のセットアップ
setup_cursor() {
    log_start "Cursor のセットアップを開始します..."

    # Cursor がインストールされているか確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        log_warning "Cursor がインストールされていません。スキップします。"
        return
    fi

    # Cursor 設定ディレクトリの作成（存在しない場合）
    CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
    if [[ ! -d "$CURSOR_CONFIG_DIR" ]]; then
        mkdir -p "$CURSOR_CONFIG_DIR"
        log_success "Cursor 設定ディレクトリを作成しました"
    fi

    # 設定の復元スクリプトが存在するか確認し、実行
    if [[ -f "$REPO_ROOT/cursor/restore_cursor_settings.sh" ]]; then
        log_start "Cursor 設定を復元しています..."
        bash "$REPO_ROOT/cursor/restore_cursor_settings.sh"
        
        # 設定ファイルが正しく復元されたか確認
        REQUIRED_SETTINGS=("settings.json" "keybindings.json" "extensions.json")
        for setting in "${REQUIRED_SETTINGS[@]}"; do
            if [[ -f "$CURSOR_CONFIG_DIR/$setting" ]]; then
                log_success "$setting が正常に復元されました"
            else
                log_warning "$setting の復元に失敗しました"
            fi
        done
    else
        log_warning "Cursor の復元スクリプトが見つかりません。設定の復元をスキップします。"
    fi

    # Flutter SDK のパスを Cursor に適用
    if command_exists flutter; then
        FLUTTER_PATH=$(which flutter)
        FLUTTER_SDK_PATH=$(dirname $(dirname $(readlink -f "$FLUTTER_PATH")))
        
        if [[ -d "$FLUTTER_SDK_PATH" ]]; then
            CURSOR_SETTINGS="$CURSOR_CONFIG_DIR/settings.json"
            
            log_start "Flutter SDK のパスを Cursor に適用中..."
            if [[ -f "$CURSOR_SETTINGS" ]]; then
                # 現在のFlutterパス設定を確認
                CURRENT_PATH=$(cat "$CURSOR_SETTINGS" | grep -o '"dart.flutterSdkPath": "[^"]*"' | cut -d'"' -f4 || echo "")
                
                if [[ "$CURRENT_PATH" != "$FLUTTER_SDK_PATH" ]]; then
                    # settings.jsonにFlutter SDKパスを追加
                    if ! command_exists jq; then
                        log_warning "jqコマンドが見つかりません。手動でsettings.jsonを更新してください。"
                    else
                        jq --arg path "$FLUTTER_SDK_PATH" '.["dart.flutterSdkPath"] = $path' "$CURSOR_SETTINGS" > "${CURSOR_SETTINGS}.tmp" && mv "${CURSOR_SETTINGS}.tmp" "$CURSOR_SETTINGS"
                        log_success "Flutter SDK のパスを $FLUTTER_SDK_PATH に更新しました！"
                    fi
                else
                    log_success "Flutter SDK のパスはすでに正しく設定されています"
                fi
            else
                log_warning "Cursor の設定ファイルが見つかりません"
            fi
        else
            log_warning "Flutter SDK のパスを特定できませんでした"
        fi
    fi

    log_success "Cursor のセットアップ完了"
}

# Xcode とシミュレータのインストール
install_xcode() {
    log_start "Xcode のインストールを開始します..."
    local xcode_install_success=true

    # Xcode Command Line Tools のインストール
    if ! xcode-select -p &>/dev/null; then
        log_start "Xcode Command Line Tools をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            # CI環境ではすでにインストールされていることを前提とする
            log_info "CI環境では Xcode Command Line Tools はすでにインストールされていると想定します"
        else
            xcode-select --install
            # インストールが完了するまで待機
            log_info "インストールが完了するまで待機..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        log_success "Xcode Command Line Tools のインストール完了"
    else
        log_success "Xcode Command Line Tools はすでにインストール済み"
    fi

    # xcodes がインストールされているか確認
    if ! command_exists xcodes; then
        log_error "xcodes がインストールされていません。インストールします..."
        if brew install xcodes; then
            log_success "xcodes をインストールしました"
        else
            log_error "xcodes のインストールに失敗しました"
            xcode_install_success=false
            return 1
        fi
    fi

    # Xcode 16.2 がインストールされているか確認
    if command_exists xcodes; then
        if ! xcodes installed | grep -q "16.2"; then
            log_start "Xcode 16.2 をインストール中..."
            if ! xcodes install 16.2 --select; then
                log_error "Xcode 16.2 のインストールに失敗しました"
                xcode_install_success=false
                return 1
            fi
        else
            log_success "Xcode 16.2 はすでにインストールされています"
            
            # Xcodeがインストールされている場合、パス設定が必要か確認
            log_info "Xcodeのパス設定を確認中..."
            local current_xcode_path=$(xcode-select -p)
            local expected_xcode_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1)
            
            # 現在のパスがXcodeのDeveloperディレクトリを指しているかチェック
            if [[ -n "$current_xcode_path" && "$current_xcode_path" == *"/Contents/Developer" && ! "$current_xcode_path" == *"CommandLineTools"* ]]; then
                log_success "Xcodeのパスは正しく設定されています: $current_xcode_path"
            elif [ -n "$expected_xcode_path" ]; then
                log_info "Xcodeが見つかりました: $expected_xcode_path"
                # Xcodeのパスを設定
                log_info "Xcodeのパスを設定します"
                if xcode-select --switch "$expected_xcode_path/Contents/Developer" 2>/dev/null; then
                    log_success "Xcodeのパスを設定しました"
                else
                    # sudo権限が必要な場合のみプロンプト表示
                    prompt_for_sudo "Xcodeのパスを設定する"
                    if sudo xcode-select --switch "$expected_xcode_path/Contents/Developer" 2>/dev/null; then
                        log_success "Xcodeのパスを設定しました"
                    else
                        log_warning "Xcodeのパス設定に失敗しましたが、続行します"
                        log_info "必要に応じて次のコマンドを手動で実行してください: sudo xcode-select --switch \"$expected_xcode_path/Contents/Developer\""
                    fi
                fi
            else
                log_warning "Xcodeのパスが見つかりません。ただし続行します"
            fi
        fi
    else
        xcode_install_success=false
        log_error "xcodes が使用できないため、Xcode 16.2 をインストールできません"
        return 1
    fi

    # シミュレータのインストール
    if [ "$xcode_install_success" = true ]; then
        log_start "シミュレータの確認中..."
        local need_install=false
        local platforms=("iOS" "watchOS" "tvOS" "visionOS")
        
        # シミュレータのチェック方法を改善
        for platform in "${platforms[@]}"; do
            # シミュレータの検証を複数の方法で実施
            local simulator_found=false
            
            # 方法1: xcrun simctl list runtime でチェック
            if xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                simulator_found=true
                log_success "$platform シミュレータが見つかりました (simctl)"
            # 方法2: Runtimesディレクトリをチェックするがファイルの中身も確認
            elif [ -d "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" ] && ls -la "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" 2>/dev/null | grep -q "$platform"; then
                # ディレクトリが存在し、かつ中身も確認
                if [ -n "$(find "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" -name "*$platform*" -type d 2>/dev/null)" ]; then
                    simulator_found=true
                    log_success "$platform シミュレータが見つかりました (ファイルシステム)"
                fi
            fi
            
            # 方法3: デバイスリストに存在するか確認
            if ! $simulator_found && xcrun simctl list devices 2>/dev/null | grep -q "$platform"; then
                simulator_found=true
                log_success "$platform 用のデバイスが存在します"
            fi
            
            # シミュレータが見つからない場合は再インストールが必要
            if ! $simulator_found; then
                need_install=true
                log_info "❓ $platform シミュレータが見つかりません。インストールが必要です。"
            fi
        done

        # シミュレータのインストールが必要な場合
        if [ "$need_install" = true ]; then
            log_start "必要なシミュレータをインストール中..."
            
            # Xcodeが正しく設定されているか確認
            local xcode_selected_path=$(xcode-select -p)
            if [[ "$xcode_selected_path" == *"CommandLineTools"* ]]; then
                log_warning "Xcodeが正しく設定されていません。現在のパス: $xcode_selected_path"
                
                # Xcodeを自動検出して設定
                local xcode_app_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1)
                if [ -n "$xcode_app_path" ]; then
                    prompt_for_sudo "シミュレータのインストールのためXcodeのパスを設定"
                    if sudo xcode-select --switch "$xcode_app_path/Contents/Developer" 2>/dev/null; then
                        log_success "Xcodeのパスを設定しました: $xcode_app_path/Contents/Developer"
                    else
                        log_warning "sudo権限がないため、シミュレータのインストールをスキップします"
                        log_info "次のコマンドを手動で実行してください: sudo xcode-select --switch \"$xcode_app_path/Contents/Developer\""
                        log_info "その後、Xcodeを起動し、Preferences -> Components からシミュレータをインストールしてください"
                        return 0  # エラーとして扱わず続行
                    fi
                else
                    log_warning "Xcodeが見つかりません。シミュレータのインストールをスキップします"
                    return 0  # エラーとして扱わず続行
                fi
            fi
            
            # シミュレータのインストール
            for platform in "${platforms[@]}"; do
                # シミュレータの検証を複数の方法で実施
                local simulator_found=false
                
                # 同じチェックを再度実行
                if xcrun simctl list runtimes 2>/dev/null | grep -q "$platform" || \
                   ([ -d "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" ] && \
                   [ -n "$(find "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" -name "*$platform*" -type d 2>/dev/null)" ]); then
                    simulator_found=true
                fi
                
                # シミュレータが見つからない場合はインストールを試みる
                if ! $simulator_found; then
                    log_info "➕ $platform シミュレータをインストール中..."
                    if ! xcodebuild -downloadPlatform "$platform"; then
                        log_warning "$platform シミュレータのインストールに失敗しました"
                        log_info "Xcodeを起動し、Settings -> Platforms から手動でインストールしてください"
                    else
                        log_success "$platform シミュレータをインストールしました"
                    fi
                fi
            done
            
            # インストール後の最終チェック
            log_info "シミュレータの状態を確認中..."
            xcrun simctl list runtimes 2>/dev/null | grep -E 'iOS|watchOS|tvOS|visionOS' || echo "利用可能なランタイムがありません"
        else
            log_success "すべての必要なシミュレータは既にインストールされています"
        fi
    else
        log_error "Xcode のインストールに失敗したため、シミュレータのインストールをスキップします"
        return 1
    fi

    # Xcode インストール後に SwiftLint をインストール
    if [ "$xcode_install_success" = true ] && ! command_exists swiftlint; then
        log_start "SwiftLint をインストール中..."
        if brew install swiftlint; then
            log_success "SwiftLint のインストールが完了しました"
        else
            log_error "SwiftLint のインストールに失敗しました"
            return 1
        fi
    elif command_exists swiftlint; then
        log_success "SwiftLint はすでにインストールされています"
    fi

    if [ "$xcode_install_success" = true ]; then
        log_success "Xcode とシミュレータのインストールが完了しました！"
        return 0
    else
        log_error "Xcode またはシミュレータのインストールに失敗しました"
        return 1
    fi
}

# Mac のシステム設定を適用
setup_mac_settings() {
    log_start "Mac のシステム設定を適用中..."
    
    # 設定ファイルの存在確認
    if [[ ! -f "$REPO_ROOT/macos/setup_mac_settings.sh" ]]; then
        log_warning "setup_mac_settings.sh が見つかりません"
        return 1
    fi
    
    # 設定ファイルの内容を確認
    log_info "📝 Mac 設定ファイルをチェック中..."
    local setting_count=$(grep -v "^#" "$REPO_ROOT/macos/setup_mac_settings.sh" | grep -v "^$" | grep -E "defaults write" | wc -l | tr -d ' ')
    log_info "🔍 $setting_count 個の設定項目が検出されました"
    
    # CI環境では適用のみスキップ
    if [ "$IS_CI" = "true" ]; then
        log_info "ℹ️ CI環境では Mac システム設定の適用をスキップします（検証のみ実行）"
        
        # 主要な設定カテゴリを確認
        for category in "Dock" "Finder" "screenshots"; do
            if grep -q "$category" "$REPO_ROOT/macos/setup_mac_settings.sh"; then
                log_success "$category に関する設定が含まれています"
            fi
        done
        
        return 0
    fi
    
    # 非CI環境では設定を適用
    # エラーがあっても続行し、完全に失敗した場合のみエラー表示
    if ! source "$REPO_ROOT/macos/setup_mac_settings.sh" 2>/dev/null; then
        log_warning "Mac 設定の適用中に一部エラーが発生しました"
        log_info "エラーを無視して続行します"
    else
        log_success "Mac のシステム設定が適用されました"
    fi
    
    # 設定が正常に適用されたか確認（一部の設定のみ）
    for setting in "com.apple.dock" "com.apple.finder"; do
        if defaults read "$setting" &>/dev/null; then
            log_success "${setting##*.} の設定が正常に適用されました"
        else
            log_warning "${setting##*.} の設定の適用に問題がある可能性があります"
        fi
    done
    
    return 0
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    log_start "SSH エージェントをセットアップ中..."
    
    # SSH エージェントを起動
    eval "$(ssh-agent -s)"
    
    # SSH キーが存在するか確認し、なければ作成
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        log_info "SSH キーが見つかりません。新しく生成します..."
        
        # .gitconfigからメールアドレスを取得
        local git_email=$(git config --get user.email)
        if [ -z "$git_email" ]; then
            log_warning ".gitconfigにメールアドレスが設定されていません"
            git_email="your_email@example.com"
        fi
        
        if [ "$IS_CI" = "true" ]; then
            log_info "CI環境では対話型のSSHキー生成をスキップします"
            # CI環境では非対話型でキーを生成（実際のメールアドレスは使用しない）
            ssh-keygen -t ed25519 -C "ci-test@example.com" -f "$HOME/.ssh/id_ed25519" -N "" -q
        else
            ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
        fi
        log_success "SSH キーの生成が完了しました"
    fi

    # SSH キーをエージェントに追加
    log_info "SSH キーを SSH エージェントに追加中..."
    if ssh-add "$HOME/.ssh/id_ed25519"; then
        log_success "SSH キーが正常に追加されました"
    else
        log_warning "SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
    fi
}

# GitHub CLI のインストールと認証
setup_github_cli() {
    if ! command_exists gh; then
        log_start "GitHub CLI をインストール中..."
        brew install gh
        log_success "GitHub CLI のインストール完了"
    else
        log_success "GitHub CLI はすでにインストールされています"
    fi

        # 待機メッセージを表示
        echo "⏳ GitHub CLIの認証確認中..."

    # 認証状態をチェック
    if ! gh auth status &>/dev/null; then
        log_info "GitHub CLI の認証が必要です"
        
        # CI環境での処理
        if [ "$IS_CI" = "true" ]; then
            if [ -n "$GITHUB_TOKEN_CI" ]; then
                log_info "CI環境用のGitHubトークンを使用して認証を行います"
                echo "$GITHUB_TOKEN_CI" | gh auth login --with-token
                if [ $? -eq 0 ]; then
                    log_success "CI環境でのGitHub認証が完了しました"
                else
                    log_warning "CI環境でのGitHub認証に失敗しました"
                fi
            else
                log_info "CI環境ではトークンがないため、認証はスキップします"
            fi
            return 0
        fi
        
        
        # ユーザーに認証をスキップするか尋ねる
        local skip_auth=""
        read -p "GitHub CLI の認証をスキップしますか？ (y/N): " skip_auth
        
        if [[ "$skip_auth" =~ ^[Yy]$ ]]; then
            log_info "GitHub CLI の認証をスキップします"
            log_warning "後で必要に応じて 'gh auth login' を実行してください（README参照）"
            return 0
        else
            log_info "GitHub CLI の認証を行います..."
            gh auth login || log_warning "GitHub認証に失敗しました。後で手動で認証してください。"
        fi
    else
        log_success "GitHub CLI はすでに認証済みです"
    fi
}

# メインスクリプトの実行
main
