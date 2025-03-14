#!/bin/bash

# CI環境かどうかを検出
IS_CI=${CI:-false}

start_time=$(date +%s)
echo "Macをセットアップ中..."

# リポジトリのルートディレクトリを設定
if [ "$IS_CI" = "true" ] && [ -n "$GITHUB_WORKSPACE" ]; then
    REPO_ROOT="$GITHUB_WORKSPACE"
else
    REPO_ROOT="$HOME/environment"
fi

# コマンドが存在するかチェックするヘルパー関数
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 終了ステータスを追跡する変数
INSTALL_SUCCESS=true

# Apple M1, M2 向け Rosetta 2 のインストール
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Mac のチップモデルを取得
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        echo "🖥 Mac Model: $MAC_MODEL"

        # M1 または M2 の場合のみ Rosetta 2 をインストール
        if [[ "$MAC_MODEL" == *"M1"* || "$MAC_MODEL" == *"M2"* ]]; then
            # すでに Rosetta 2 がインストールされているかチェック
            if pgrep oahd >/dev/null 2>&1; then
                echo "✅ Rosetta 2 はすでにインストール済み"
                return
            fi

            # Rosetta 2 をインストール
            echo "🔄 Rosetta 2 を $MAC_MODEL 向けにインストール中..."
            if [ "$IS_CI" = "true" ]; then
                # CI環境では非対話型でインストール
                softwareupdate --install-rosetta --agree-to-license || true
            else
                softwareupdate --install-rosetta --agree-to-license
            fi

            # インストールの成否をチェック
            if pgrep oahd >/dev/null 2>&1; then
                echo "✅ Rosetta 2 のインストールが完了した"
            else
                echo "❌ Rosetta 2 のインストールに失敗した"
                INSTALL_SUCCESS=false
            fi
        else
            echo "✅ この Mac ($MAC_MODEL) には Rosetta 2 は不要"
        fi
    else
        echo "✅ この Mac は Apple Silicon ではないため、Rosetta 2 は不要"
    fi
}


install_homebrew() {
    if ! command_exists brew; then
        echo "Homebrew をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            echo "CI環境では非対話型でインストールします"
            # CI環境では非対話型でインストール
            NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        else
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        
        # Homebrew PATH設定を即時有効化
        if [[ "$(uname -m)" == "arm64" ]]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            eval "$(/usr/local/bin/brew shellenv)"
        fi
        
        echo "✅ Homebrew のインストール完了"
    else
        echo "✅ Homebrew はすでにインストール済み"
    fi
}

setup_shell_config() {
    echo "シェルの設定を適用中..."
    
    # ディレクトリとファイルの存在確認
    if [[ ! -d "$REPO_ROOT/shell" ]]; then
        echo "❌ $REPO_ROOT/shell ディレクトリが見つからない"
        INSTALL_SUCCESS=false
        return 1
    fi
    
    if [[ ! -f "$REPO_ROOT/shell/.zprofile" ]]; then
        echo "❌ $REPO_ROOT/shell/.zprofile ファイルが見つからない"
        INSTALL_SUCCESS=false
        return 1
    fi
    
    # .zprofileファイルをシンボリックリンクとして設定
    if [[ -L "$HOME/.zprofile" || -f "$HOME/.zprofile" ]]; then
        # 既存のファイルやシンボリックリンクが存在する場合は削除
        rm -f "$HOME/.zprofile"
    fi
    
    # シンボリックリンクを作成
    ln -sf "$REPO_ROOT/shell/.zprofile" "$HOME/.zprofile"
    
    # 設定を反映（CI環境ではスキップ）
    if [ "$IS_CI" != "true" ] && [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi
    
    echo "✅ シェルの設定を適用完了"
}

# Git の設定を適用
setup_git_config() {
    # シンボリックリンクを作成
    ln -sf "$REPO_ROOT/git/.gitconfig" "${HOME}/.gitconfig"
    ln -sf "$REPO_ROOT/git/.gitignore_global" "${HOME}/.gitignore_global"
    
    git config --global core.excludesfile "${HOME}/.gitignore_global"
    echo "✅ Git の設定を適用完了"
}

# Brewfile に記載されているパッケージをインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/config/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        echo "⚠️ Warning: $brewfile_path が見つからないのでスキップ"
        return
    fi

    echo "Homebrew パッケージのインストールを開始します..."

    # GitHub認証の設定 (CI環境用)
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        echo "🔑 CI環境用のGitHub認証を設定中..."
        # 認証情報を環境変数に設定
        export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN_CI"
        # Gitの認証設定
        git config --global url."https://${GITHUB_ACTOR:-github-actions}:${GITHUB_TOKEN_CI}@github.com/".insteadOf "https://github.com/"
    fi

    # CI環境でも全てのパッケージをインストール
    if ! brew bundle --file "$brewfile_path"; then
        echo "⚠️ 一部のパッケージのインストールに失敗しました"
        INSTALL_SUCCESS=false
    else
        echo "✅ Homebrew パッケージのインストールが完了しました"
    fi
}

# Flutter のセットアップ
setup_flutter() {
    if ! command_exists flutter; then
        echo "Flutter がインストールされていません。セットアップをスキップします。"
        return
    fi

    # Flutterのパスを確認
    FLUTTER_PATH=$(which flutter)
    echo "Flutter PATH: $FLUTTER_PATH"
    
    # パスが正しいか確認
    if [[ "$FLUTTER_PATH" != "/opt/homebrew/bin/flutter" ]]; then
        echo "⚠️ Flutterが期待するパスにインストールされていません"
        echo "現在のパス: $FLUTTER_PATH"
        echo "期待するパス: /opt/homebrew/bin/flutter"
        INSTALL_SUCCESS=false
    fi

    # Android SDK の cmdline-tools が正しく設定されているか確認
    ANDROID_SDK_ROOT="$HOME/Library/Android/sdk"
    CMDLINE_TOOLS_PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest"
    
    echo "🔄 Android SDK のセットアップを確認中..."
    
    # Android SDK ディレクトリが存在するか確認
    if [ ! -d "$ANDROID_SDK_ROOT" ]; then
        echo "Android SDK ディレクトリを作成します..."
        mkdir -p "$ANDROID_SDK_ROOT"
    fi
    
    # android-commandlinetoolsとJavaが利用可能か確認
    if ! command -v sdkmanager &>/dev/null; then
        echo "⚠️ Android Command Line Toolsが見つかりません（Brewfileでインストールされるはず）"
        INSTALL_SUCCESS=false
    fi
    
    if ! command -v java &>/dev/null; then
        echo "⚠️ Javaが見つかりません（Brewfileでtemurinがインストールされるはず）"
        INSTALL_SUCCESS=false
    fi
    
    # cmdline-tools のパスが正しいか確認
    if [ ! -d "$CMDLINE_TOOLS_PATH" ]; then
        echo "Android SDK のコマンドラインツールをセットアップ中..."
        
        # Homebrew でインストールされた Android SDK Command Line Tools のパス
        BREW_CMDLINE_TOOLS="/opt/homebrew/share/android-commandlinetools/cmdline-tools/latest"
        
        if [ -d "$BREW_CMDLINE_TOOLS" ]; then
            echo "Homebrew でインストールされたコマンドラインツールを設定中..."
            
            # cmdline-tools ディレクトリ構造を作成
            mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
            
            # latest シンボリックリンクを作成
            ln -sf "$BREW_CMDLINE_TOOLS" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
            
            echo "✅ Android SDK コマンドラインツールをセットアップしました"
        else
            echo "❌ Homebrew の Android SDK コマンドラインツールが見つかりません"
            echo "config/Brewfileから自動的にインストールされるはずです"
            INSTALL_SUCCESS=false
        fi
    fi
    
    # 環境変数を設定
    export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
    export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"
    
    # sdkmanager を使って必要なパッケージをインストール
    if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
        echo "🔄 Android SDK コンポーネントを確認中..."
        
        # すでにインストールされているパッケージを確認
        INSTALLED_PACKAGES=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --list 2>/dev/null | grep -E "^Installed packages:" -A100 | grep -v "^Available" | grep -v "^Installed")
        
        # platform-tools の確認とインストール
        if ! echo "$INSTALLED_PACKAGES" | grep -q "platform-tools"; then
            echo "platform-tools をインストール中..."
            echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" "platform-tools" > /dev/null
        else
            echo "✅ platform-tools はすでにインストール済み"
        fi
        
        # build-tools の確認とインストール
        if ! echo "$INSTALLED_PACKAGES" | grep -q "build-tools;35.0.1"; then
            echo "build-tools;35.0.1 をインストール中..."
            echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" "build-tools;35.0.1" > /dev/null
        else
            echo "✅ build-tools;35.0.1 はすでにインストール済み"
        fi
        
        # platforms の確認とインストール
        if ! echo "$INSTALLED_PACKAGES" | grep -q "platforms;android-34"; then
            echo "platforms;android-34 をインストール中..."
            echo "y" | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" "platforms;android-34" > /dev/null
        else
            echo "✅ platforms;android-34 はすでにインストール済み"
        fi
        
        echo "✅ Android SDK コンポーネントの確認が完了しました"
    else
        echo "❌ sdkmanager が見つかりません"
        INSTALL_SUCCESS=false
    fi

    # Flutter doctorの実行
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では対話型の flutter doctor --android-licenses をスキップします"
        flutter doctor || true
    else
        # ライセンス同意状態を確認
        LICENSE_STATUS=$("$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses --status 2>&1 | grep -c "All SDK package licenses accepted." || echo "0")
        
        if [ "$LICENSE_STATUS" = "0" ]; then
            echo "🔄 Android SDK ライセンスに同意中..."
            if [ -f "$CMDLINE_TOOLS_PATH/bin/sdkmanager" ]; then
                # 全てのライセンスに自動で同意
                yes | "$CMDLINE_TOOLS_PATH/bin/sdkmanager" --licenses > /dev/null
                echo "✅ Android SDK ライセンスに同意しました"
                
                # 明示的にflutter doctorでAndroidライセンスに同意
                flutter doctor --android-licenses
            fi
        else
            echo "✅ Android SDK ライセンスはすでに同意済みです"
        fi
        
        echo "🔄 Flutter doctor を実行中..."
        flutter doctor -v || INSTALL_SUCCESS=false
    fi

    echo "✅ Flutter の環境のセットアップ完了"
}

# Cursor のセットアップ
setup_cursor() {
    echo "🔄 Cursor のセットアップを開始します..."

    # Cursor がインストールされているか確認
    if ! ls /Applications/Cursor.app &>/dev/null; then
        echo "❌ Cursor がインストールされていません。スキップします。"
        return
    fi

    # Cursor 設定ディレクトリの作成（存在しない場合）
    CURSOR_CONFIG_DIR="$HOME/Library/Application Support/Cursor/User"
    if [[ ! -d "$CURSOR_CONFIG_DIR" ]]; then
        mkdir -p "$CURSOR_CONFIG_DIR"
        echo "✅ Cursor 設定ディレクトリを作成しました"
    fi

    # 設定の復元スクリプトが存在するか確認し、実行
    if [[ -f "$REPO_ROOT/cursor/restore_cursor_settings.sh" ]]; then
        echo "🔄 Cursor 設定を復元しています..."
        bash "$REPO_ROOT/cursor/restore_cursor_settings.sh"
        
        # 設定ファイルが正しく復元されたか確認
        REQUIRED_SETTINGS=("settings.json" "keybindings.json" "extensions.json")
        for setting in "${REQUIRED_SETTINGS[@]}"; do
            if [[ -f "$CURSOR_CONFIG_DIR/$setting" ]]; then
                echo "✅ $setting が正常に復元されました"
            else
                echo "⚠️ $setting の復元に失敗しました"
                INSTALL_SUCCESS=false
            fi
        done
    else
        echo "Cursor の復元スクリプトが見つかりません。設定の復元をスキップします。"
        INSTALL_SUCCESS=false
    fi

    # Flutter SDK のパスを Cursor に適用
    if command -v flutter &>/dev/null; then
        FLUTTER_PATH=$(which flutter)
        FLUTTER_SDK_PATH=$(dirname $(dirname $(readlink -f "$FLUTTER_PATH")))
        
        if [[ -d "$FLUTTER_SDK_PATH" ]]; then
            CURSOR_SETTINGS="$CURSOR_CONFIG_DIR/settings.json"
            
            echo "🔧 Flutter SDK のパスを Cursor に適用中..."
            if [[ -f "$CURSOR_SETTINGS" ]]; then
                # 現在のFlutterパス設定を確認
                CURRENT_PATH=$(cat "$CURSOR_SETTINGS" | grep -o '"dart.flutterSdkPath": "[^"]*"' | cut -d'"' -f4 || echo "")
                
                if [[ "$CURRENT_PATH" != "$FLUTTER_SDK_PATH" ]]; then
                    # settings.jsonにFlutter SDKパスを追加
                    if ! command -v jq &>/dev/null; then
                        echo "⚠️ jqコマンドが見つかりません。手動でsettings.jsonを更新してください。"
                    else
                        jq --arg path "$FLUTTER_SDK_PATH" '.["dart.flutterSdkPath"] = $path' "$CURSOR_SETTINGS" > "${CURSOR_SETTINGS}.tmp" && mv "${CURSOR_SETTINGS}.tmp" "$CURSOR_SETTINGS"
                        echo "✅ Flutter SDK のパスを $FLUTTER_SDK_PATH に更新しました！"
                    fi
                else
                    echo "✅ Flutter SDK のパスはすでに正しく設定されています"
                fi
            else
                echo "⚠️ Cursor の設定ファイルが見つかりません"
            fi
        else
            echo "⚠️ Flutter SDK のパスを特定できませんでした"
        fi
    fi

    echo "✅ Cursor のセットアップ完了"
}

# Xcode とシミュレータのインストール
install_xcode() {
    echo "🔄 Xcode のインストールを開始します..."
    local xcode_install_success=true

    # Xcode Command Line Tools のインストール
    if ! xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            # CI環境ではすでにインストールされていることを前提とする
            echo "CI環境では Xcode Command Line Tools はすでにインストールされていると想定します"
        else
            xcode-select --install
            # インストールが完了するまで待機
            echo "インストールが完了するまで待機..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        echo "✅ Xcode Command Line Tools のインストール完了"
    else
        echo "✅ Xcode Command Line Tools はすでにインストール済み"
    fi

    # xcodes がインストールされているか確認
    if ! command -v xcodes >/dev/null 2>&1; then
        echo "❌ xcodes がインストールされていません。インストールします..."
        if brew install xcodes; then
            echo "✅ xcodes をインストールしました"
        else
            echo "❌ xcodes のインストールに失敗しました"
            xcode_install_success=false
            INSTALL_SUCCESS=false
        fi
    fi

    # Xcode 16.2 がインストールされているか確認
    if command -v xcodes >/dev/null 2>&1; then
        if ! xcodes installed | grep -q "16.2"; then
            echo "📱 Xcode 16.2 をインストール中..."
            if ! xcodes install 16.2 --select; then
                echo "❌ Xcode 16.2 のインストールに失敗しました"
                xcode_install_success=false
                INSTALL_SUCCESS=false
            fi
        else
            echo "✅ Xcode 16.2 はすでにインストールされています"
        fi
    else
        xcode_install_success=false
        echo "❌ xcodes が使用できないため、Xcode 16.2 をインストールできません"
    fi

    # シミュレータのインストール
    if [ "$xcode_install_success" = true ]; then
        echo "📲 シミュレータの確認中..."
        local need_install=false
        for platform in iOS watchOS tvOS visionOS; do
            if ! xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                need_install=true
                echo "❓ $platform シミュレータが見つかりません"
            else
                echo "✅ $platform シミュレータは既にインストールされています"
            fi
        done

        # シミュレータのインストールが必要な場合のみインストール処理を実行
        if [ "$need_install" = true ]; then
            echo "📲 不足しているシミュレータをインストール中..."
            for platform in iOS watchOS tvOS visionOS; do
                if ! xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                    echo "➕ $platform シミュレータをインストール中..."
                    if ! xcodebuild -downloadPlatform "$platform"; then
                        echo "❌ $platform シミュレータのインストールに失敗しました"
                        INSTALL_SUCCESS=false
                    fi
                fi
            done
        else
            echo "✅ すべてのシミュレータは既にインストールされています"
        fi
    else
        echo "❌ Xcode のインストールに失敗したため、シミュレータのインストールをスキップします"
    fi

    # Xcode インストール後に SwiftLint をインストール
    if [ "$xcode_install_success" = true ] && ! command -v swiftlint >/dev/null 2>&1; then
        echo "🔄 SwiftLint をインストール中..."
        if brew install swiftlint; then
            echo "✅ SwiftLint のインストールが完了しました"
        else
            echo "❌ SwiftLint のインストールに失敗しました"
            INSTALL_SUCCESS=false
        fi
    elif command -v swiftlint >/dev/null 2>&1; then
        echo "✅ SwiftLint はすでにインストールされています"
    fi

    if [ "$xcode_install_success" = true ]; then
        echo "✅ Xcode とシミュレータのインストールが完了しました！"
        
        return 0
    else
        echo "❌ Xcode またはシミュレータのインストールに失敗しました"
        return 1
    fi
}

# Mac のシステム設定を適用
setup_mac_settings() {
    echo "🖥 Mac のシステム設定を適用中..."
    
    # 設定ファイルの存在確認
    if [[ ! -f "$REPO_ROOT/macos/setup_mac_settings.sh" ]]; then
        echo "⚠️ setup_mac_settings.sh が見つかりません"
        INSTALL_SUCCESS=false
        return 1
    fi
    
    # 設定ファイルの内容を確認
    echo "📝 Mac 設定ファイルをチェック中..."
    local setting_count=$(grep -v "^#" "$REPO_ROOT/macos/setup_mac_settings.sh" | grep -v "^$" | grep -E "defaults write" | wc -l | tr -d ' ')
    echo "🔍 $setting_count 個の設定項目が検出されました"
    
    # CI環境では適用のみスキップ
    if [ "$IS_CI" = "true" ]; then
        echo "ℹ️ CI環境では Mac システム設定の適用をスキップします（検証のみ実行）"
        
        # 主要な設定カテゴリを確認
        if grep -q "Dock" "$REPO_ROOT/macos/setup_mac_settings.sh"; then
            echo "✅ Dock に関する設定が含まれています"
        fi
        
        if grep -q "Finder" "$REPO_ROOT/macos/setup_mac_settings.sh"; then
            echo "✅ Finder の設定が含まれています"
        fi
        
        if grep -q "screenshots" "$REPO_ROOT/macos/setup_mac_settings.sh"; then
            echo "✅ スクリーンショットの保存先の設定が含まれています"
        fi
        
        return 0
    fi
    
    # 非CI環境では設定を適用
    source "$REPO_ROOT/macos/setup_mac_settings.sh" || {
        echo "❌ Mac 設定の適用中にエラーが発生しました"
        INSTALL_SUCCESS=false
        return 1
    }
    
    echo "✅ Mac のシステム設定が適用されました"
    
    # 設定が正常に適用されたか確認（一部の設定のみ）
    if defaults read com.apple.dock &>/dev/null; then
        echo "✅ Dock の設定が正常に適用されました"
    else
        echo "⚠️ Dock の設定の適用に問題がある可能性があります"
        INSTALL_SUCCESS=false
    fi
    
    if defaults read com.apple.finder &>/dev/null; then
        echo "✅ Finder の設定が正常に適用されました"
    else
        echo "⚠️ Finder の設定の適用に問題がある可能性があります"
        INSTALL_SUCCESS=false
    fi
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    echo "🔐 SSH エージェントをセットアップ中..."
    
    # SSH エージェントを起動
    eval "$(ssh-agent -s)"
    
    # SSH キーが存在するか確認し、なければ作成
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "🛠 SSH キーが見つかりません。新しく生成します..."
        
        # .gitconfigからメールアドレスを取得
        local git_email=$(git config --get user.email)
        if [ -z "$git_email" ]; then
            echo "⚠️ .gitconfigにメールアドレスが設定されていません"
            git_email="your_email@example.com"
        fi
        
        if [ "$IS_CI" = "true" ]; then
            echo "CI環境では対話型のSSHキー生成をスキップします"
            # CI環境では非対話型でキーを生成（実際のメールアドレスは使用しない）
            ssh-keygen -t ed25519 -C "ci-test@example.com" -f "$HOME/.ssh/id_ed25519" -N "" -q
        else
            ssh-keygen -t ed25519 -C "$git_email" -f "$HOME/.ssh/id_ed25519" -N ""
        fi
        echo "✅ SSH キーの生成が完了しました"
    fi

    # SSH キーをエージェントに追加
    echo "🔑 SSH キーを SSH エージェントに追加中..."
    if ssh-add "$HOME/.ssh/id_ed25519"; then
        echo "✅ SSH キーが正常に追加されました"
    else
        echo "⚠️ SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
        INSTALL_SUCCESS=false
    fi
}

# GitHub CLI のインストールと認証
setup_github_cli() {
    if ! command_exists gh; then
        echo "GitHub CLI をインストール中..."
        brew install gh
        echo "✅ GitHub CLI のインストール完了"
    else
        echo "✅ GitHub CLI はすでにインストールされています"
    fi

    # 認証状態をチェック
    if ! gh auth status &>/dev/null; then
        echo "GitHub CLI の認証を行います..."
        if [ "$IS_CI" = "true" ]; then
            echo "CI環境ではトークンがないため、認証はスキップします"
            # CI環境では認証情報がないため、実際の認証はスキップ
        else
            gh auth login || INSTALL_SUCCESS=false
        fi
    else
        echo "✅ GitHub CLI はすでに認証済みです"
    fi
}

# 実行順序
install_rosetta        # Apple M1, M2 向けに Rosetta 2 をインストール
install_homebrew       # Homebrew をインストール
setup_shell_config     # zsh の設定を適用
setup_git_config       # Git の設定と gitignore_global を適用
setup_ssh_agent        # SSH キーのエージェントを設定
setup_github_cli       # GitHub CLIのセットアップ
setup_mac_settings     # Mac のシステム設定を復元
install_brewfile       # Brewfile のパッケージをインストール

# Xcodeのインストールを実行（同期的に）
echo "🔄 Xcodeのインストールを開始します..."
if ! install_xcode; then
    echo "❌ Xcodeのインストールに問題がありました"
    INSTALL_SUCCESS=false
else
    echo "✅ Xcodeのインストールが完了しました"
fi

# Xcodeに依存するものをインストール
setup_flutter          # Flutter の開発環境をセットアップ
setup_cursor           # Cursorのセットアップ

# インストール結果の表示
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))

if [ "$INSTALL_SUCCESS" = true ]; then
    echo "🎉 すべてのインストールと設定が完了しました！"
    echo "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"
else
    echo "⚠️ セットアップは完了しましたが、一部の処理に問題がありました。"
    echo "ログを確認して、必要に応じて個別にインストールや設定を行ってください。"
    echo "セットアップ完了（所要時間: ${elapsed_time}秒）"
fi

# 新しいシェルセッションを開始
exec $SHELL -l 