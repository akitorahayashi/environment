#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

changed=false

# Homebrewのインストール
if ! command -v brew &> /dev/null; then
    echo "[INSTALL] Homebrew ..."
    changed=true
    
    install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    echo "[INFO] Homebrewインストールスクリプトを実行します..."
    if [ "${CI}" = "true" ]; then
        echo "[INFO] CI環境では非対話型でインストールします"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL $install_url)"
    else
        /bin/bash -c "$(curl -fsSL $install_url)"
    fi
    
    eval "$($(brew --prefix)/bin/brew shellenv)"
    
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

if [ -f "$brewfile_path" ]; then
    if [ "${CI:-false}" = "true" ]; then
        # CI環境ではインストールせず存在確認のみ
        if brew bundle check --file="$brewfile_path"; then
            echo "[SUCCESS] CI: すべてのパッケージがインストールされています"
        else
            echo "[ERROR] CI: Brewfileで定義されたパッケージの一部がインストールされていません。"
            exit 1
        fi
    else
        temp_output=$(mktemp)
        if ! brew bundle --file "$brewfile_path" 2>&1 | tee "$temp_output"; then
            rm -f "$temp_output"
            echo "[ERROR] Brewfileからのパッケージインストールに失敗しました"
            exit 1
        fi

        if grep -E "(Installing|Upgrading|Downloading)" "$temp_output" > /dev/null; then
            changed=true
            echo "[OK] Homebrew パッケージのインストール/アップグレードが完了しました"
        else
            echo "[OK] Homebrew パッケージは既に最新の状態です"
        fi
        rm -f "$temp_output"
    fi
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "[SUCCESS] Homebrewのセットアップが完了しました"

# Homebrew環境の検証
echo "[Start] Homebrew環境を検証中..."
verification_failed=false

# Homebrew パスの確認
BREW_PATH=$(which brew)
expected_path="$(brew --prefix)/bin/brew"
if [[ "$BREW_PATH" != "$expected_path" ]]; then
    echo "[ERROR] Homebrewのパスが想定と異なります"
    echo "[ERROR] 期待: $expected_path"
    echo "[ERROR] 実際: $BREW_PATH"
    verification_failed=true
else
    echo "[SUCCESS] Homebrewのパスが正しく設定されています: $BREW_PATH"
fi

# パッケージの確認
if [ -f "$brewfile_path" ]; then
    if ! brew bundle check --file="$brewfile_path"; then
        echo "[ERROR] Brewfileで定義されたパッケージの一部がインストールされていません。"
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