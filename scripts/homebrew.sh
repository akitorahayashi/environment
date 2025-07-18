#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# CI環境かどうかを確認
export IS_CI=${CI:-false}

main() {
    # Homebrewのインストール
    install_homebrew
    
    # Brewfileのインストール
    echo ""
    echo "[Start] Homebrew パッケージのインストールを開始します..."
    local brewfile_path="$REPO_ROOT/config/brew/Brewfile"
    install_packages_from_brewfile "$brewfile_path"
    
    echo "[SUCCESS] Homebrewのセットアップが完了しました"

    verify_homebrew_setup
}

install_homebrew() {
    if ! command -v brew; then
        echo "[INSTALL] Homebrew ..."
        echo "STATE_CHANGED" >&2
        install_homebrew_binary # バイナリインストール後、この関数内でPATH設定も行う
        echo "[SUCCESS] Homebrew のインストール完了"
    else
        echo "[SUCCESS] Homebrew はすでにインストールされています"
    fi
}

install_homebrew_binary() {
    local install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    
    echo "[INFO] Homebrewインストールスクリプトを実行します..."
    if [ "$IS_CI" = "true" ]; then
        echo "[INFO] CI環境では非対話型でインストールします"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $install_url)"
    else
        /bin/bash -c "$(curl -fsSL $install_url)"
    fi
    
    # インストールスクリプト実行後、現在のシェルセッションにPATHを設定
    # これにより、次のcommand -v brewが正しく機能するようになる
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    # インストール結果確認 (この時点でbrewコマンドが利用可能になっているはず)
    if ! command -v brew; then
        echo "[ERROR] Homebrewのインストールに失敗しました"
        exit 1
    fi
    echo "[OK] Homebrewバイナリのインストールが完了しました。"
}

install_packages_from_brewfile() {
    local brewfile_path="$1"
    
    # brew bundleの出力を一時ファイルに保存
    local temp_output=$(mktemp)
    
    if ! brew bundle --file "$brewfile_path" 2>&1 | tee "$temp_output"; then
        rm -f "$temp_output"
        echo "[ERROR] Brewfileからのパッケージインストールに失敗しました"
        exit 1
    fi
    
    # 出力を解析して実際にインストールやアップグレードが発生したかチェック
    if grep -E "(Installing|Upgrading|Downloading)" "$temp_output" > /dev/null; then
        echo "STATE_CHANGED" >&2
        echo "[OK] Homebrew パッケージのインストール/アップグレードが完了しました"
    else
        echo "[OK] Homebrew パッケージは既に最新の状態です"
    fi
    
    rm -f "$temp_output"
}

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
        echo "[ERROR] Homebrewのパスが想定と異なります"
        echo "[ERROR] 期待: $expected_path"
        echo "[ERROR] 実際: $BREW_PATH"
        return 1
    else
        echo "[SUCCESS] "Homebrewのパスが正しく設定されています: $BREW_PATH""
        return 0
    fi
}

verify_individual_packages() {
    local brewfile_path="$1"
    local missing=0
    
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        # brew および cask パッケージを抽出・確認
        if [[ $line =~ ^brew\ "([^\"]*)" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "formula" || ((missing++))
        elif [[ $line =~ ^cask\ "([^\"]*)" ]]; then
            verify_brew_package "${BASH_REMATCH[1]}" "cask" || ((missing++))
        fi
    done < "$brewfile_path"
    
    echo "$missing"
}

verify_brew_package() {
    local package="$1"
    local type="$2"
    
    if [ "$type" = "formula" ]; then
        if ! brew list --formula "$package" &>/dev/null; then
            echo "[ERROR] formula $package がインストールされていません"
            return 1
        else
            echo "[SUCCESS] "formula $package がインストールされています""
            return 0
        fi
    elif [ "$type" = "cask" ]; then
        if ! brew list --cask "$package" &>/dev/null; then
            echo "[ERROR] cask $package がインストールされていません"
            return 1
        else
            echo "[SUCCESS] "cask $package がインストールされています""
            return 0
        fi
    fi
}

verify_homebrew_setup() {
    echo "[Start] Homebrew環境を検証中..."
    local verification_failed=false

    # Homebrew パスの確認
    verify_brew_path || verification_failed=true

    # パッケージの確認
    local brewfile_path="$REPO_ROOT/config/brew/Brewfile"
    if [ -f "$brewfile_path" ]; then
        local missing_packages
        missing_packages=$(verify_individual_packages "$brewfile_path")
        if [ "$missing_packages" -gt 0 ]; then
            echo "[ERROR] $missing_packages 個のパッケージが不足しています"
            verification_failed=true
        else
            echo "[SUCCESS] すべてのパッケージがインストールされています"
        fi
    else
        echo "[WARN] Brewfileが見つかりません: $brewfile_path"
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Homebrew環境の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] Homebrew環境の検証が完了しました"
        return 0
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi