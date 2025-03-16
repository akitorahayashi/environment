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

# スクリプトのメイン実行 - 関数が宣言される前に呼び出しを行っても問題ない
trap main EXIT

# ログ出力用のヘルパー関数
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

# エラー処理関数
handle_error() {
    log_error "$1"
    log_error "スクリプトを終了します。"
    exit 1
}

# コマンドが存在するかチェックするヘルパー関数
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
        log_info "🖥 Mac Model: $MAC_MODEL"

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
    local auto_accept=$1
    
    if [ "$auto_accept" = "true" ]; then
        # 全てのライセンスに自動で同意
        yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses > /dev/null || handle_error "Android SDK ライセンスへの同意に失敗しました"
        yes | flutter doctor --android-licenses || handle_error "flutter doctor --android-licenses の実行に失敗しました"
    else
        # ライセンス同意状態を確認
        LICENSE_STATUS=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses --status 2>&1 | grep -c "All SDK package licenses accepted." || echo "0")
        
        if [ "$LICENSE_STATUS" = "0" ]; then
            log_start "Android SDK ライセンスに同意中..."
            if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
                # 全てのライセンスに自動で同意
                yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses > /dev/null || handle_error "Android SDK ライセンスへの同意に失敗しました"
                log_success "Android SDK ライセンスに同意しました"
                
                # 明示的にflutter doctorでAndroidライセンスに同意
                flutter doctor --android-licenses || handle_error "flutter doctor --android-licenses の実行に失敗しました"
            fi
        else
            log_success "Android SDK ライセンスはすでに同意済みです"
        fi
    fi
}

# Android SDKコンポーネントをインストールする関数
install_android_sdk_components() {
    if [ ! -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
        handle_error "sdkmanager が見つかりません"
    fi
    
    log_start "Android SDK コンポーネントを確認中..."
    
    # すでにインストールされているパッケージを確認
    INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
    
    # 必要なコンポーネントのリスト
    SDK_COMPONENTS=("platform-tools" "build-tools;35.0.1" "platforms;android-34")
    
    # 各コンポーネントをチェックしてインストール
    for component in "${SDK_COMPONENTS[@]}"; do
        if ! echo "$INSTALLED_PACKAGES" | grep -q "$component"; then
            log_start "$component をインストール中..."
            if ! echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" "$component" > /dev/null; then
                handle_error "$component のインストールに失敗しました"
            fi
        else
            log_success "$component はすでにインストール済み"
        fi
    done
    
    log_success "Android SDK コンポーネントの確認が完了しました"
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
        
        for platform in "${platforms[@]}"; do
            if ! xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                need_install=true
                log_info "❓ $platform シミュレータが見つかりません"
            else
                log_success "$platform シミュレータは既にインストールされています"
            fi
        done

        # シミュレータのインストールが必要な場合のみインストール処理を実行
        if [ "$need_install" = true ]; then
            log_start "不足しているシミュレータをインストール中..."
            for platform in "${platforms[@]}"; do
                if ! xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                    log_info "➕ $platform シミュレータをインストール中..."
                    if ! xcodebuild -downloadPlatform "$platform"; then
                        log_error "$platform シミュレータのインストールに失敗しました"
                        return 1
                    fi
                fi
            done
        else
            log_success "すべてのシミュレータは既にインストールされています"
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
    source "$REPO_ROOT/macos/setup_mac_settings.sh" || {
        log_error "Mac 設定の適用中にエラーが発生しました"
        return 1
    }
    
    log_success "Mac のシステム設定が適用されました"
    
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

    # 認証状態をチェック
    if ! gh auth status &>/dev/null; then
        log_info "GitHub CLI の認証を行います..."
        if [ "$IS_CI" = "true" ]; then
            log_info "CI環境ではトークンがないため、認証はスキップします"
        else
            gh auth login || log_warning "GitHub認証に失敗しました。後で手動で認証してください。"
        fi
    else
        log_success "GitHub CLI はすでに認証済みです"
    fi
} 