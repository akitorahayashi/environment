#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh" || { echo "[ERROR] helpers.shをロードできませんでした。処理を終了します。" && exit 2; }

# インストール実行フラグ
installation_performed=false

# CI環境かどうかを確認
export IS_CI=${CI:-false}

# Xcode Command Line Toolsのインストール
install_xcode_command_line_tools() {
    # Xcode Command Line Tools のインストール
    if ! xcode-select -p &>/dev/null; then
        echo "[INSTALL] Xcode Command Line Tools ..."
        installation_performed=true
        if [ "$IS_CI" = "true" ]; then
            # CI環境ではすでにインストールされていることを前提とする
            echo "[INFO] CI環境では Xcode Command Line Tools はすでにインストールされていると想定します"
        else
            xcode-select --install
            # インストールが完了するまで待機
            echo "[INFO] インストールが完了するまで待機..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        echo "[OK] Xcode Command Line Tools のインストール完了"
    else
        echo "[OK] Xcode Command Line Tools ... already installed"
    fi
    
    return 0
}

# Homebrew のインストール
install_homebrew() {
    # まずXcode Command Line Toolsをインストール
    install_xcode_command_line_tools
    
    if ! command_exists brew; then
        echo "[INSTALL] Homebrew ..."
        installation_performed=true
        install_homebrew_binary # バイナリインストール後、この関数内でPATH設定も行う
        echo "[OK] Homebrew のインストール完了"
    else
        echo "[OK] Homebrew ... already installed"
    fi
}

# Homebrewバイナリのインストール
install_homebrew_binary() {
    local install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    echo "[INFO] Homebrewインストールスクリプトを実行します..."
    if [ "$IS_CI" = "true" ]; then
        echo "[INFO] CI環境では非対話型でインストールします"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $install_url)"
    else
        /bin/bash -c "$(curl -fsSL $install_url)"
    fi
    
    # インストールスクリプト実行後、直ちに現在のシェルセッションにPATHを設定
    # これにより、次のcommand_exists brewが正しく機能するようになる
    setup_homebrew_path # <-- ここに移動し、現在のセッションと永続的なPATH設定を行う
    
    # インストール結果確認 (この時点でbrewコマンドが利用可能になっているはず)
    if ! command_exists brew; then
        echo "[ERROR] Homebrewのインストールに失敗しました"
        exit 2
    fi
    echo "[OK] Homebrewバイナリのインストールが完了しました。"
}

# Homebrew PATH設定
setup_homebrew_path() {
    local brew_shellenv_cmd
    local shell_config_file="$HOME/.zprofile" # zshユーザー向け。bashなら~/.bash_profileや~/.bashrc

    if [[ "$(uname -m)" == "arm64" ]]; then
        brew_shellenv_cmd="/opt/homebrew/bin/brew shellenv"
    else
        brew_shellenv_cmd="/usr/local/bin/brew shellenv"
    fi

    # 現在のセッションにPATHを設定（スクリプト実行中にbrewが使えるようにするため）
    eval "$($brew_shellenv_cmd)"
    echo "[INFO] 現在のシェルセッションにHomebrewのPATHを設定しました。"
    
    # .zprofile (または適切なシェル設定ファイル) に永続的に追加
    # 既に設定があるかチェックし、なければ追加する
    if ! grep -q "eval \"\$($brew_shellenv_cmd)\"" "$shell_config_file" 2>/dev/null; then
        echo "[INFO] HomebrewのPATHを $shell_config_file に永続的に追加します。"
        echo 'eval "$('$brew_shellenv_cmd')"' >> "$shell_config_file"
    else
        echo "[INFO] HomebrewのPATHは既に $shell_config_file に設定済みです。"
    fi
}

# Brewfileの内容をインストール/更新する関数
install_brewfile() {
    echo ""
    echo "==== Start: Brewfileのインストール/更新を開始します... ===="
    local brewfile_path="$REPO_ROOT/config/brew/Brewfile"
    
    if [ ! -f "$brewfile_path" ]; then
        echo "[ERROR] Brewfileが見つかりません: $brewfile_path"
        exit 2
    fi

    echo ""
    echo "==== Start: Homebrew パッケージのインストールを開始します... ===="
    setup_github_auth_for_brew
    install_packages_from_brewfile "$brewfile_path"
}

# GitHub認証設定（CI環境用）
setup_github_auth_for_brew() {
    if [ -n "$GITHUB_TOKEN_CI" ]; then
        echo "[INFO] 🔑 CI環境用のGitHub認証を設定中..."
        # 認証情報を環境変数に設定
        export HOMEBREW_GITHUB_API_TOKEN="$GITHUB_TOKEN_CI"
        # Gitの認証設定
        git config --global url."https://${GITHUB_ACTOR:-github-actions}:${GITHUB_TOKEN_CI}@github.com/".insteadOf "https://github.com/"
    fi
}

# Brewfileからパッケージインストール
install_packages_from_brewfile() {
    local brewfile_path="$1"
    
    # brew bundleの出力を一時ファイルに保存
    local temp_output=$(mktemp)
    
    if ! brew bundle --file "$brewfile_path" 2>&1 | tee "$temp_output"; then
        rm -f "$temp_output"
        echo "[ERROR] Brewfileからのパッケージインストールに失敗しました"
        exit 2
    fi
    
    # 出力を解析して実際にインストールやアップグレードが発生したかチェック
    if grep -E "(Installing|Upgrading|Downloading)" "$temp_output" > /dev/null; then
        installation_performed=true
        echo "[OK] Homebrew パッケージのインストール/アップグレードが完了しました"
    else
        echo "[OK] Homebrew パッケージは既に最新の状態です"
    fi
    
    rm -f "$temp_output"
}

# Homebrewのインストールを検証
verify_homebrew_setup() {
    echo "==== Start: "Homebrewの環境を検証中...""
    local verification_failed=false
    
    # Xcode Command Line Toolsの確認
    verify_xcode_command_line_tools || verification_failed=true
    
    # brewコマンドの確認
    if ! verify_brew_command; then
        return 1
    fi
    
    # バージョン確認
    verify_brew_version || verification_failed=true
    
    # パス確認
    verify_brew_path || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] "Homebrewの検証に失敗しました""
        return 1
    else
        echo "[SUCCESS] "Homebrewの検証が完了しました""
        return 0
    fi
}

# brewコマンドの検証
verify_brew_command() {
    if ! command_exists brew; then
        echo "[ERROR] "brewコマンドが見つかりません""
        return 1
    fi
    echo "[SUCCESS] "brewコマンドが正常に使用可能です""
    return 0
}

# Homebrewバージョンの検証
verify_brew_version() {
    if [ "$IS_CI" = "true" ]; then
        # CI環境では最小限の出力
        BREW_VERSION=$(brew --version | head -n 1 2>/dev/null || echo "不明")
        if [ "$BREW_VERSION" = "不明" ]; then
            echo "[WARN] "Homebrewのバージョン取得に問題が発生しましたが続行します""
            return 0
        else
            echo "[SUCCESS] "Homebrewのバージョン: $BREW_VERSION""
            return 0
        fi
    else
        # 通常環境での確認
        if ! brew --version > /dev/null; then
            echo "[ERROR] "Homebrewのバージョン確認に失敗しました""
            return 1
        fi
        echo "[SUCCESS] "Homebrewのバージョン: $(brew --version | head -n 1)""
        return 0
    fi
}

# Homebrewパスの検証
verify_brew_path() {
    BREW_PATH=$(which brew)
    local expected_path=""
    
    # アーキテクチャに応じた期待値
    if [[ "$(uname -m)" == "arm64" ]]; then
        expected_path="/opt/homebrew/bin/brew"
    else
        expected_path="/usr/local/bin/brew"
    fi
    
    if [[ "$BREW_PATH" != "$expected_path" ]]; then
        echo "[ERROR] "Homebrewのパスが想定と異なります""
        echo "[ERROR] "期待: $expected_path""
        echo "[ERROR] "実際: $BREW_PATH""
        return 1
    else
        echo "[SUCCESS] "Homebrewのパスが正しく設定されています: $BREW_PATH""
        return 0
    fi
}

# Brewfileの検証
verify_brewfile() {
    local brewfile_path="${1:-$REPO_ROOT/config/brew/Brewfile}"
    if [ ! -f "$brewfile_path" ]; then
        echo "[ERROR] "Brewfileが見つかりません: $brewfile_path""
        return 1
    fi
    echo "[SUCCESS] "Brewfileが存在します: $brewfile_path""
    return 0
}



# 個別パッケージ確認
verify_individual_packages() {
    local brewfile_path="$1"
    local missing=0
    
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        # brew および cask パッケージを抽出・確認
        if [[ $line =~ ^brew\ \"([^\"]*)\" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "formula" || ((missing++))
        elif [[ $line =~ ^cask\ \"([^\"]*)\" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "cask" || ((missing++))
        fi
    done < "$brewfile_path"
    
    echo "$missing"
}

# 個別パッケージの確認
verify_brew_package() {
    local package="$1"
    local type="$2"
    
    if [ "$type" = "formula" ]; then
        if ! brew list --formula "$package" &>/dev/null; then
            echo "[ERROR] "formula $package がインストールされていません""
            return 1
        else
            echo "[SUCCESS] "formula $package がインストールされています""
            return 0
        fi
    elif [ "$type" = "cask" ]; then
        if ! brew list --cask "$package" &>/dev/null; then
            echo "[ERROR] "cask $package がインストールされていません""
            return 1
        else
            echo "[SUCCESS] "cask $package がインストールされています""
            return 0
        fi
    fi
}

# Xcode Command Line Toolsの検証
verify_xcode_command_line_tools() {
    if ! xcode-select -p &>/dev/null; then
        echo "[ERROR] "Xcode Command Line Toolsがインストールされていません""
        return 1
    else
        echo "[SUCCESS] "Xcode Command Line Toolsがインストールされています""
        return 0
    fi
}

# メイン関数
main() {
    echo ""
    echo "==== Start: Homebrewのセットアップを開始します ===="
    
    # Homebrewのインストール
    install_homebrew
    
    # Brewfileのインストール
    install_brewfile
    
    echo "[OK] Homebrewのセットアップが完了しました"
    
    # 終了ステータスの決定
    if [ "$installation_performed" = "true" ]; then
        exit 0  # インストール実行済み
    else
        exit 1  # インストール不要（冪等性保持）
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi