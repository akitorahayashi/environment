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
            echo "インストールが完了するまで待機..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        echo "✅ Xcode Command Line Tools のインストール完了"
    else
        echo "✅ Xcode Command Line Tools はすでにインストール済み"
    fi
}

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
        return 1
    fi
    
    if [[ ! -f "$REPO_ROOT/shell/.zprofile" ]]; then
        echo "❌ $REPO_ROOT/shell/.zprofile ファイルが見つからない"
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

# アプリを開く関数
open_app() {
    local package_name="$1"
    local bundle_name="$2"
    
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境ではアプリの起動をスキップ: $package_name"
        return
    fi
    
    echo "✨ $package_name を起動中..."
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
            echo "🚀 $package_name を起動中..."
            if ! open -a "$bundle_name" 2>/dev/null; then
                echo "⚠️ $package_name の起動に失敗"
            fi
            return
        fi
    done
    
    echo "$package_name が見つからない"
}

# Brewfile に記載されているパッケージをインストール
install_brewfile() {
    local brewfile_path="$REPO_ROOT/config/Brewfile"
    
    if [[ ! -f "$brewfile_path" ]]; then
        echo "⚠️ Warning: $brewfile_path が見つからないのでスキップ"
        return
    fi

    echo "Homebrew パッケージのインストールを開始します..."

    if [ "$IS_CI" = "true" ]; then
        # CI環境では最小限のパッケージのみインストール
        echo "CI環境では最小限のパッケージをインストールします"
        brew install git xcodes cursor || true
        return
    fi

    # 通常環境では全パッケージをインストール
    brew bundle --file "$brewfile_path"
    echo "✅ Homebrew パッケージのインストールが完了しました"
}

# Flutter のセットアップ
setup_flutter() {
    if ! command_exists flutter; then
        echo "Flutter がインストールされていません。セットアップをスキップします。"
        return
    fi

    echo "Flutter の環境をセットアップ中..."

    if [ "$IS_CI" = "true" ]; then
        echo "CI環境では対話型の flutter doctor --android-licenses をスキップします"
        flutter doctor || true
    else
        flutter doctor --android-licenses
    fi

    echo "✅ Flutter の環境のセットアップ完了"
}

# Cursor のセットアップ
setup_cursor() {
    echo "🔄 Cursor のセットアップを開始します..."


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

    # CI環境ではXcodeのインストールをスキップ
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境ではXcodeのインストールと設定をスキップします"
        return 0
    fi

    # xcodes がインストールされているか確認
    if ! command -v xcodes >/dev/null 2>&1; then
        echo "❌ xcodes がインストールされていません。先に Brewfile を適用してください。"
        return 1
    fi

    # Xcode 16.2 がインストールされているか確認
    if ! xcodes installed | grep -q "16.2"; then
        echo "📱 Xcode 16.2 をインストール中..."
        xcodes install 16.2 --select
    else
        echo "✅ Xcode 16.2 はすでにインストールされています"
    fi

    # シミュレータのインストール
    echo "📲 シミュレータをインストール中..."
    for platform in iOS watchOS tvOS visionOS; do
        if ! xcrun simctl list runtimes | grep -q "$platform"; then
            echo "➕ $platform シミュレータをインストール中..."
            xcodebuild -downloadPlatform "$platform"
        else
            echo "✅ $platform シミュレータは既にインストールされています"
        fi
    done

    echo "✅ Xcode のセットアップが完了しました！"
}

# Mac のシステム設定を適用
setup_mac_settings() {
    echo "🖥 Mac のシステム設定を適用中..."
    
    # CI環境ではスキップ
    if [ "$IS_CI" = "true" ]; then
        echo "CI環境ではMacシステム設定の適用をスキップします"
        return 0
    fi
    
    if [[ -f "$REPO_ROOT/macos/setup_mac_settings.sh" ]]; then
        source "$REPO_ROOT/macos/setup_mac_settings.sh"
        echo "✅ Mac のシステム設定が適用されました"
    else
        echo "setup_mac_settings.sh が見つかりません"
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
            gh auth login
        fi
    else
        echo "✅ GitHub CLI はすでに認証済みです"
    fi
}

# 実行順序
install_xcode_tools     # 開発に必要な Xcode Command Line Tools をインストール
install_rosetta        # Apple M1, M2 向けに Rosetta 2 をインストール
install_homebrew       # Homebrew をインストール
install_brewfile      # Brewfile のパッケージをインストール
setup_shell_config    # zsh の設定を適用
setup_github_cli      # GitHub CLIのセットアップ

setup_git_config      # Git の設定と gitignore_global を適用
setup_ssh_agent      # SSH キーのエージェントを設定

setup_mac_settings    # Mac のシステム設定を復元
setup_xcode          # Xcode 16.2 とシミュレータのインストール
setup_flutter        # Flutter の開発環境をセットアップ
setup_cursor         # Cursor IDE の設定を復元

end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
echo "セットアップ完了 🎉（所要時間: ${elapsed_time}秒）"

exec $SHELL -l