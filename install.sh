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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Xcode Command Line Tools のインストール（非対話的）
install_xcode_tools() {
    if ! xcode-select -p &>/dev/null; then
        echo "Xcode Command Line Tools をインストール中..."
        if [ "$IS_CI" = "true" ]; then
            # CI環境ではすでにインストールされていることを前提とする
            echo "CI環境では Xcode Command Line Tools はすでにインストールされていると想定します"
        else
            xcode-select --install
            # インストールが完了するまで待機
            echo "インストールが完了するまで待機しています..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        echo "Xcode Command Line Tools のインストール完了 ✅"
    else
        echo "Xcode Command Line Tools はすでにインストールされています"
    fi
}

# Apple M1, M2 向け Rosetta 2 のインストール
install_rosetta() {
    if [[ "$(uname -m)" == "arm64" ]]; then
        # Mac のチップモデルを取得
        MAC_MODEL=$(sysctl -n machdep.cpu.brand_string)
        echo "Mac Model: $MAC_MODEL"  # デバッグ出力

        # M1 または M2 の場合のみ Rosetta 2 をインストール
        if [[ "$MAC_MODEL" == *"M1"* || "$MAC_MODEL" == *"M2"* ]]; then
            # すでに Rosetta 2 がインストールされているかチェック
            if pgrep oahd >/dev/null 2>&1; then
                echo "Rosetta 2 はすでにインストールされています ✅"
                return
            fi

            # Rosetta 2 をインストール
            echo "Rosetta 2 を $MAC_MODEL 向けにインストール中..."
            softwareupdate --install-rosetta --agree-to-license

            # インストールの成否をチェック
            if pgrep oahd >/dev/null 2>&1; then
                echo "Rosetta 2 のインストールが完了しました ✅"
            else
                echo "Rosetta 2 のインストールに失敗しました ❌"
            fi
        else
            echo "この Mac ($MAC_MODEL) には Rosetta 2 は不要です ✅"
        fi
    else
        echo "この Mac は Apple Silicon ではないため、Rosetta 2 は不要です ✅"
    fi
}


install_homebrew() {
    if ! command_exists brew; then
        echo "Homebrew をインストール中..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        echo "Homebrew のインストール完了 ✅"
    else
        echo "Homebrew はすでにインストールされています"
    fi
}

setup_shell_config() {
    echo "シェルの設定を適用中..."
    
    if [ "$IS_CI" = "true" ]; then
        # CI環境でも本番環境と同じように設定ファイルをコピー
        echo "CI環境でシェル設定ファイルをコピーします"
        
        # shell/ディレクトリが存在しない場合は作成
        mkdir -p "$REPO_ROOT/shell"
        
        # 空の.zshrcファイルを作成
        touch "$REPO_ROOT/shell/.zshrc"
        
        # 空の.zprofileファイルを作成
        touch "$REPO_ROOT/shell/.zprofile"
    fi
    
    # リポジトリから設定ファイルをコピー（CI環境と本番環境共通）
    cp "$REPO_ROOT/shell/.zshrc" "$HOME/.zshrc"
    cp "$REPO_ROOT/shell/.zprofile" "$HOME/.zprofile"
    
    # 設定を反映
    if [ -f "$HOME/.zprofile" ]; then
        source "$HOME/.zprofile"
    fi
    if [ -f "$HOME/.zshrc" ]; then
        source "$HOME/.zshrc"
    fi
    
    echo "シェルの設定の適用完了 ✅"
}

# Git の設定を適用
setup_git_config() {
    # シンボリックリンクを作成
    ln -sf "$REPO_ROOT/git/.gitconfig" "${HOME}/.gitconfig"
    ln -sf "$REPO_ROOT/git/.gitignore_global" "${HOME}/.gitignore_global"
    
    git config --global core.excludesfile "${HOME}/.gitignore_global"
    echo "Git 設定を適用しました ✅"
}

# アプリを開く関数
open_app() {
    local package_name="$1"
    local bundle_name="$2"
    
    echo "✨ $package_name を起動準備中..."
    # インストール完了後、少し待機
    sleep 2
    
    # 複数のパスをチェック
    local app_paths=(
        "/Applications/${bundle_name}"
        "$HOME/Applications/${bundle_name}"
        "/opt/homebrew/Caskroom/${package_name}/latest/${bundle_name}"
    )
    
    for app_path in "${app_paths[@]}"; do
        if [ -d "$app_path" ]; then
            echo "🚀 $package_name を起動します..."
            if ! open -a "$bundle_name" 2>/dev/null; then
                echo "⚠️ $package_name の起動に失敗しました"
            fi
            return
        fi
    done
    
    echo "⚠️ $package_name が見つかりません"
}

# Brewfile に記載されているパッケージをインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/config/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        echo "Warning: $brewfile_path が見つかりません。スキップします。"
        return
    fi

    echo "Homebrew パッケージの状態を確認中..."

    # インストール済みのパッケージリストを一度だけ取得
    local installed_formulas=$(brew list --formula)
    local installed_casks=$(brew list --cask)

    # Brewfile からインストールすべきパッケージを1行ずつ処理
    while IFS= read -r line; do
        # コメントや空行をスキップ
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue

        # "brew" または "cask" で始まる行をパース
        if [[ "$line" =~ ^brew\ \"(.*)\"$ ]]; then
            package_name="${BASH_REMATCH[1]}"
            
            # インストール済みリストから確認
            if echo "$installed_formulas" | grep -q "^$package_name\$"; then
                echo "✔ $package_name はすでにインストールされています"
            else
                echo "➕ $package_name をインストール中..."
                brew install "$package_name"
            fi

        elif [[ "$line" =~ ^cask\ \"(.*)\"$ ]]; then
            package_name="${BASH_REMATCH[1]}"
            
            # インストール済みリストから確認
            if echo "$installed_casks" | grep -q "^$package_name\$"; then
                echo "✔ $package_name はすでにインストールされています"
            else
                echo "➕ $package_name をインストール中..."
                if brew install --cask "$package_name"; then
                    # アプリ名とバンドル名のマッピング
                    local bundle_name=""
                    case "$package_name" in
                        "android-studio")
                            bundle_name="Android Studio.app"
                            ;;
                        "google-chrome")
                            bundle_name="Google Chrome.app"
                            ;;
                        "slack")
                            bundle_name="Slack.app"
                            ;;
                        "spotify")
                            bundle_name="Spotify.app"
                            ;;
                        "zoom")
                            bundle_name="zoom.us.app"
                            ;;
                        "notion")
                            bundle_name="Notion.app"
                            ;;
                        "figma")
                            bundle_name="Figma.app"
                            ;;
                        "cursor")
                            bundle_name="Cursor.app"
                            ;;
                    esac

                    # バンドル名が設定されている場合のみ開く
                    if [ -n "$bundle_name" ]; then
                        open_app "$package_name" "$bundle_name"
                    fi
                else
                    echo "❌ $package_name のインストールに失敗しました"
                fi
            fi
        fi
    done < "$brewfile_path"

    echo "Homebrew パッケージの適用が完了しました ✅"
}

# Flutter のセットアップ（Android SDK のパスを適切に設定）
setup_flutter() {
    if ! command_exists flutter; then
        echo "Flutter がインストールされていません。セットアップをスキップします。"
        return
    fi

    echo "Flutter 環境をセットアップ中..."
    
    # Android SDK のパスを適切に設定
    export ANDROID_HOME="$HOME/Library/Android/sdk"
    export ANDROID_SDK_ROOT="$ANDROID_HOME"
    export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$PATH"

    if [ "$IS_CI" = "true" ]; then
        echo "CI環境ではflutter doctorをスキップします"
    else
        flutter doctor --android-licenses
        flutter doctor
    fi

    echo "Flutter 環境のセットアップ完了 ✅"
}

# Cursor のセットアップ
setup_cursor() {
    echo "🔄 Cursor のセットアップを開始します..."

    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では Cursor のセットアップをスキップします"
        return 0
    fi

    # Cursor がインストールされているか確認
    if ! command -v cursor &>/dev/null; then
        echo "❌ Cursor がインストールされていません。スキップします。"
        return
    fi

    # 設定の復元スクリプトが存在するか確認し、実行
    if [[ -f "$REPO_ROOT/cursor/restore_cursor_settings.sh" ]]; then
        bash "$REPO_ROOT/cursor/restore_cursor_settings.sh"
    else
        echo "Cursor の復元スクリプトが見つかりません。設定の復元をスキップします。"
    fi

    # Flutter SDK のパスを Cursor に適用
    if [ -d "/opt/homebrew/Caskroom/flutter" ]; then
        FLUTTER_VERSION=$(ls /opt/homebrew/Caskroom/flutter | sort -rV | head -n 1)
        FLUTTER_SDK_PATH="/opt/homebrew/Caskroom/flutter/${FLUTTER_VERSION}/flutter"

        if [[ -d "$FLUTTER_SDK_PATH" ]]; then
            CURSOR_SETTINGS="$REPO_ROOT/cursor/settings.json"
            
            echo "🔧 Flutter SDK のパスを Cursor に適用中..."
            jq --arg path "$FLUTTER_SDK_PATH" '.["dart.flutterSdkPath"] = $path' "$CURSOR_SETTINGS" > "${CURSOR_SETTINGS}.tmp" && mv "${CURSOR_SETTINGS}.tmp" "$CURSOR_SETTINGS"
            echo "✅ Flutter SDK のパスを $FLUTTER_SDK_PATH に設定しました！"
        else
            echo "⚠️ Flutter SDK のディレクトリが見つかりませんでした。"
        fi
    else
        echo "⚠️ Homebrew の Flutter Caskroom ディレクトリが見つかりませんでした。"
    fi

    echo "✅ Cursor のセットアップが完了しました！"
}

# Xcode の設定
setup_xcode() {
    echo "🔄 Xcode の設定中..."

    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では Xcode のセットアップをスキップします"
        return 0
    fi

    # xcodes がインストールされているか確認
    if ! command -v xcodes >/dev/null 2>&1; then
        echo "❌ xcodes がインストールされていません。先に Brewfile を適用してください。"
        return 1
    fi

    # Xcode 16.2 がインストールされているか確認
    if ! xcodes installed --formula | grep -q "16.2"; then
        echo "📱 Xcode 16.2 をインストール中..."
        xcodes install 16.2 --select
    else
        echo "✅ Xcode 16.2 はすでにインストールされています"
    fi

    # シミュレータのインストール
    echo "📲 各プラットフォームのシミュレータを確認中..."
    
    # シミュレータがインストール済みかチェックする関数
    check_simulator() {
        local platform="$1"
        local runtime_name="$2"
        
        # xcrun simctl list runtimes でインストール済みのランタイムを確認
        if xcrun simctl list runtimes | grep -q "$runtime_name"; then
            return 0  # インストール済み
        else
            return 1  # 未インストール
        fi
    }
    
    # iOS シミュレータ
    if check_simulator "iOS" "iOS"; then
        echo "✅ iOS シミュレータは既にインストールされています"
    else
        echo "📱 iOS シミュレータをインストール中..."
        xcodebuild -downloadPlatform iOS
    fi
    
    # watchOS シミュレータ
    if check_simulator "watchOS" "watchOS"; then
        echo "✅ watchOS シミュレータは既にインストールされています"
    else
        echo "⌚ watchOS シミュレータをインストール中..."
        xcodebuild -downloadPlatform watchOS
    fi
    
    # tvOS シミュレータ
    if check_simulator "tvOS" "tvOS"; then
        echo "✅ tvOS シミュレータは既にインストールされています"
    else
        echo "📺 tvOS シミュレータをインストール中..."
        xcodebuild -downloadPlatform tvOS
    fi
    
    # visionOS シミュレータ
    if check_simulator "visionOS" "visionOS"; then
        echo "✅ visionOS シミュレータは既にインストールされています"
    else
        echo "👓 visionOS シミュレータをインストール中..."
        xcodebuild -downloadPlatform visionOS
    fi
    
    echo "✅ すべてのシミュレータの確認が完了しました"

    if [[ -f "$REPO_ROOT/xcode/restore_xcode_settings.sh" ]]; then
        bash "$REPO_ROOT/xcode/restore_xcode_settings.sh"
        echo "✅ Xcode 設定の適用が完了しました！"
    else
        echo "restore_xcode_settings.sh が見つかりません"
    fi
}

# Mac のシステム設定を適用
setup_mac_settings() {
    echo "🖥 Mac のシステム設定を適用中..."
    
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では Mac のシステム設定をスキップします"
        return 0
    fi
    
    if [[ -f "$REPO_ROOT/macos/setup_mac_settings.sh" ]]; then
        source "$REPO_ROOT/macos/setup_mac_settings.sh"
        echo "✅ Mac のシステム設定が適用されました"
    else
        echo "⚠️ setup_mac_settings.sh が見つかりません"
    fi
}

# SSH エージェントのセットアップ
setup_ssh_agent() {
    echo "🔐 SSH エージェントをセットアップ中..."
    
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では SSH エージェントのセットアップをスキップします"
        return 0
    fi
    
    # SSH エージェントを起動
    eval "$(ssh-agent -s)"
    
    # SSH キーが存在するか確認し、なければ作成
    if [[ ! -f "$HOME/.ssh/id_ed25519" ]]; then
        echo "🛠 SSH キーが見つかりません。新しく生成します..."
        ssh-keygen -t ed25519 -C "your_email@example.com" -f "$HOME/.ssh/id_ed25519" -N ""
        echo "✅ SSH キーの生成が完了しました"
    fi

    # SSH キーをエージェントに追加
    echo "🔑 SSH キーを SSH エージェントに追加中..."
    if ssh-add "$HOME/.ssh/id_ed25519"; then
        echo "✅ SSH キーが正常に追加されました"
    else
        echo "⚠️ SSH キーの追加に失敗しました。手動でパスフレーズを入力する必要があります"
    fi
}

# GitHub CLI のインストールと認証
setup_github_cli() {
    if ! command_exists gh; then
        echo "GitHub CLI をインストール中..."
        brew install gh
        echo "GitHub CLI のインストール完了 ✅"
    else
        echo "GitHub CLI はすでにインストールされています"
    fi

    # 認証状態をチェック
    if ! gh auth status &>/dev/null; then
        echo "GitHub CLI の認証を行います..."
        if [ "$IS_CI" = "true" ]; then
            echo "CI環境では認証をスキップします"
        else
            gh auth login
        fi
    else
        echo "GitHub CLI はすでに認証済みです ✅"
    fi
}

# 実行順序
install_xcode_tools     # 開発に必要な Xcode Command Line Tools をインストール
install_rosetta        # Apple Silicon Mac 向けに Rosetta 2 をインストール
install_homebrew       # パッケージマネージャの Homebrew をインストール
setup_shell_config    # zsh の設定を適用
setup_github_cli      # GitHub CLIのセットアップを追加
install_brewfile      # Brewfile から必要なパッケージをインストール

setup_git_config      # Git の設定とグローバル gitignore を適用
setup_ssh_agent      # SSH キーの自動追加のためのエージェントを設定

setup_mac_settings    # Mac のシステム設定（トラックパッド、Dock など）を適用
setup_xcode          # Xcode 16.2 のインストールと設定の復元
setup_flutter        # Flutter 開発環境をセットアップ
setup_cursor         # Cursor IDE の設定を復元

end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"

exec $SHELL -l