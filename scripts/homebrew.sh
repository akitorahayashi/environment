#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# Homebrewのインストール
if ! command -v brew; then
    echo "[INSTALL] Homebrew ..."
    echo "IDEMPOTENCY_VIOLATION" >&2
    
    install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    echo "[INFO] Homebrewインストールスクリプトを実行します..."
    if [ "${CI}" = "true" ]; then
        echo "[INFO] CI環境では非対話型でインストールします"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $install_url)"
    else
        /bin/bash -c "$(curl -fsSL $install_url)"
    fi
    
    if [[ "$(uname -m)" == "arm64" ]]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        eval "$(/usr/local/bin/brew shellenv)"
    fi
    
    if ! command -v brew; then
        echo "[ERROR] Homebrewのインストールに失敗しました"
        exit 1
    fi
    echo "[OK] Homebrewバイナリのインストールが完了しました。"
    echo "[SUCCESS] Homebrew のインストール完了"
else
    echo "[SUCCESS] Homebrew はすでにインストールされています"
fi

# Brewfileのインストール
echo ""
echo "[Start] Homebrew パッケージのインストールを開始します..."
brewfile_path="$REPO_ROOT/config/brew/Brewfile"

temp_output=$(mktemp)
if ! brew bundle --file "$brewfile_path" 2>&1 | tee "$temp_output"; then
    rm -f "$temp_output"
    echo "[ERROR] Brewfileからのパッケージインストールに失敗しました"
    exit 1
fi

if grep -E "(Installing|Upgrading|Downloading)" "$temp_output" > /dev/null; then
    echo "IDEMPOTENCY_VIOLATION" >&2
    echo "[OK] Homebrew パッケージのインストール/アップグレードが完了しました"
else
    echo "[OK] Homebrew パッケージは既に最新の状態です"
fi
rm -f "$temp_output"

echo "[SUCCESS] Homebrewのセットアップが完了しました"

# Homebrew環境の検証
echo "[Start] Homebrew環境を検証中..."
verification_failed=false

# Homebrew パスの確認
BREW_PATH=$(which brew)
expected_path=""
if [[ "$(uname -m)" == "arm64" ]]; then
    expected_path="/opt/homebrew/bin/brew"
else
    expected_path="/usr/local/bin/brew"
fi
if [[ "$BREW_PATH" != "$expected_path" ]]; then
    echo "[ERROR] Homebrewのパスが想定と異なります"
    echo "[ERROR] 期待: $expected_path"
    echo "[ERROR] 実際: $BREW_PATH"
    verification_failed=true
else
    echo "[SUCCESS] "Homebrewのパスが正しく設定されています: $BREW_PATH""
fi

# パッケージの確認
brewfile_path="$REPO_ROOT/config/brew/Brewfile"
if [ -f "$brewfile_path" ]; then
    missing_packages=0
    while IFS= read -r line; do
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        if [[ $line =~ ^brew\ "([^\"]*)" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew list --formula "$package" &>/dev/null; then
                echo "[ERROR] formula $package がインストールされていません"
                ((missing_packages++))
            else
                echo "[SUCCESS] "formula $package がインストールされています""
            fi
        elif [[ $line =~ ^cask\ "([^\"]*)" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew list --cask "$package" &>/dev/null; then
                echo "[ERROR] cask $package がインストールされていません"
                ((missing_packages++))
            else
                echo "[SUCCESS] "cask $package がインストールされています""
            fi
        fi
    done < "$brewfile_path"

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
    exit 1
else
    echo "[SUCCESS] Homebrew環境の検証が完了しました"
fi