#!/bin/bash

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# Function to verify brew/cask items
verify_items() {
  local type=$1
  local cmd=(brew info)
  [[ $type == "cask" ]] && cmd+=(--cask)

  while read -r item; do
    if ! "${cmd[@]}" "$item" &>/dev/null; then
      echo "[ERROR] CI: ${type} package '$item' not found."
      verification_failed=true
    else
      echo "[SUCCESS] CI: ${type} package '$item' can be installed."
    fi
  done < <(grep "^$type " "$brewfile_path" | awk -F'"' '{print $2}')
}

# Homebrewのインストール
if ! command -v brew &> /dev/null; then
    echo "    echo "[INSTALL] Installing Homebrew""
    
    install_url="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
    echo "[INFO] Executing Homebrew installation script..."
    if [ "${CI:-false}" = "true" ]; then
        echo "[INFO] Installing non-interactively in CI environment"
        NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL "$install_url")"
    else
        /bin/bash -c "$(curl -fsSL "$install_url")"
    fi
    
    
    if ! command -v brew; then
        echo "[ERROR] Homebrew installation failed"
        exit 1
    fi
    eval "$('/opt/homebrew/bin/brew' shellenv)"
    echo "[OK] Homebrew binary installation completed."
    echo "[SUCCESS] Homebrew installation completed"
else
    echo "[SUCCESS] Homebrew is already installed"
fi

# Brewfileを使ったインストール
echo ""
echo "[Start] Starting Homebrew package installation..."
brewfile_path="$CONFIG_DIR_PROPS/brew/Brewfile"

if [ -f "$brewfile_path" ]; then
    if [ "${CI:-false}" = "true" ]; then
        # CI環境ではインストールせず存在確認のみ
        echo "[INFO] CI: Checking if Brewfile packages can be installed..."
        verification_failed=false

        verify_items "brew"
        verify_items "cask"

        if [ "$verification_failed" = "true" ]; then
            echo "[ERROR] CI: Brewfileの検証に失敗しました。"
            exit 1
        else
            echo "[SUCCESS] CI: すべてのパッケージがインストール可能です。"
        fi
    else
        if ! brew bundle --file "$brewfile_path"; then
            echo "[ERROR] Package installation from Brewfile failed"
            exit 1
        fi
        echo "[OK] Homebrew package installation/upgrade completed"
    fi
fi

echo "[SUCCESS] Homebrew setup completed"

# CIでない場合のみHomebrew環境を検証
if [ "${CI:-false}" != "true" ]; then
    echo "[Start] Verifying Homebrew environment..."
    verification_failed=false

    # Homebrew パスの確認
    BREW_PATH=$(command -v brew)
    expected_path="$(brew --prefix)/bin/brew"
    if [[ "$BREW_PATH" != "$expected_path" ]]; then
        echo "[ERROR] Homebrew path differs from expected"
        echo "[ERROR] Expected: $expected_path"
        echo "[ERROR] Actual: $BREW_PATH"
        verification_failed=true
    else
        echo "[SUCCESS] Homebrew path is correctly set: $BREW_PATH"
    fi

    # パッケージの確認
    if [ -f "$brewfile_path" ]; then
        if ! brew bundle check --file="$brewfile_path"; then
            echo "[ERROR] Some packages defined in Brewfile are not installed."
            verification_failed=true
        else
            echo "[SUCCESS] All packages are installed"
        fi
    else
        echo "[WARN] Brewfile not found: $brewfile_path"
    fi

    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Homebrew environment verification failed"
        exit 1
    else
        echo "[SUCCESS] Homebrew environment verification completed"
    fi
fi