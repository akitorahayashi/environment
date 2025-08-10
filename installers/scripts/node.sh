#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するNode.jsのバージョンを定数として定義
readonly NODE_VERSION="22.17.1"

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: nvm, jq"
dependencies_changed=false
if ! brew list nvm &> /dev/null; then
    brew install nvm
    dependencies_changed=true
fi
if ! command -v jq &> /dev/null; then
    brew install jq
    dependencies_changed=true
fi
if [ "$dependencies_changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# nvm環境を読み込む
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
    # shellcheck source=/dev/null
    . "$(brew --prefix nvm)/nvm.sh"
else
    echo "[ERROR] nvm.sh が見つかりません。nvm のインストールを確認してください"
    exit 1
fi

echo "[Start] Node.js のセットアップを開始します..."

# nvm経由でNode.jsをインストール・設定
node_changed=false
if ! nvm ls "$NODE_VERSION" | grep -q "$NODE_VERSION"; then
    if nvm install "$NODE_VERSION"; then
        echo "[SUCCESS] Node.js $NODE_VERSION のインストールが完了しました"
        node_changed=true
    else
        echo "[ERROR] Node.js $NODE_VERSION のインストールに失敗しました"
        exit 1
    fi
else
    echo "[INSTALLED] Node.js $NODE_VERSION はすでにインストールされています"
fi
current_default=$(nvm alias default 2>/dev/null || true)
if [[ "$current_default" != *"$NODE_VERSION"* ]]; then
    echo "[CONFIGURING] Node.js $NODE_VERSION をデフォルトバージョンに設定します"
    if nvm alias default "$NODE_VERSION"; then
        echo "[SUCCESS] デフォルトバージョンを $NODE_VERSION に設定しました"
        node_changed=true
    else
        echo "[ERROR] デフォルトバージョンの設定に失敗しました"
        exit 1
    fi
else
    echo "[CONFIGURED] Node.js $NODE_VERSION はすでにデフォルトバージョンです"
fi
if [ "$node_changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# 現在のシェルで指定バージョンを使用
nvm use "$NODE_VERSION" > /dev/null

# npm のインストール確認
if ! command -v npm &> /dev/null; then
    echo "[ERROR] npm が見つかりません。nvm の設定と Node.js のインストールを確認してください。"
    exit 1
fi
echo "[OK] npm は利用可能です"

# グローバルパッケージのインストール
packages_file="$REPO_ROOT/config/node/global-packages.json"
if [ ! -f "$packages_file" ]; then
    echo "[WARN] global-packages.json が見つかりません。グローバルパッケージのインストールをスキップします"
else
    echo "[INFO] グローバルパッケージをチェック中..."
    packages_json=$(jq -r '.globalPackages | to_entries[] | "\(.key)@\(.value)"' "$packages_file" 2>/dev/null)
    if [ -z "$packages_json" ]; then
        echo "[WARN] global-packages.json にパッケージが定義されていません"
    else
        packages_changed=false
        echo "$packages_json" | while IFS= read -r entry; do
            pkg_full="$entry"
            pkg_name="${entry%@*}"
            installed_version=$(npm list -g --depth=0 "$pkg_name" | grep -E "$pkg_name@[0-9]" | awk -F'@' '{print $NF}' || true)
            required_version=$(echo "$pkg_full" | awk -F'@' '{print $NF}')
            if [ "$required_version" == "latest" ]; then
                if [ -z "$installed_version" ]; then
                    if npm install -g "$pkg_full"; then
                        echo "[SUCCESS] $pkg_name のインストールが完了しました"
                        packages_changed=true
                    else
                        echo "[ERROR] $pkg_name のインストールに失敗しました"
                        exit 1
                    fi
                else
                    echo "[INSTALLED] $pkg_name (latest)"
                fi
            elif [ "$installed_version" != "$required_version" ]; then
                if npm install -g "$pkg_full"; then
                    echo "[SUCCESS] $pkg_name の更新が完了しました"
                    packages_changed=true
                else
                    echo "[ERROR] $pkg_name の更新に失敗しました"
                    exit 1
                fi
            else
                echo "[INSTALLED] $pkg_name"
            fi
        done
        if [ "$packages_changed" = true ]; then
            echo "IDEMPOTENCY_VIOLATION" >&2
        fi
    fi
fi

echo "[SUCCESS] Node.js 環境のセットアップが完了しました"

# Node.js 環境の検証
echo ""
echo "==== Start: Node.js 環境を検証中... ===="
verification_failed=false
echo "[SUCCESS] Node.js: $(node --version)"
echo "[SUCCESS] npm: $(npm --version)"

packages_file="$REPO_ROOT/config/node/global-packages.json"
if [ ! -f "$packages_file" ]; then
    echo "[WARN] global-packages.json が見つかりません"
else
    packages_json=$(jq -r '.globalPackages | keys[]' "$packages_file" 2>/dev/null)
    missing=0
    if [ -n "$packages_json" ]; then
        echo "$packages_json" | while IFS= read -r package; do
            if ! npm list -g "$package" &>/dev/null; then
                echo "[ERROR] グローバルパッケージ $package がインストールされていません"
                ((missing++))
            else
                echo "[SUCCESS] グローバルパッケージ $package がインストールされています"
            fi
        done
    fi
    if [ $missing -gt 0 ]; then
        verification_failed=true
    fi
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Node.js 環境の検証に失敗しました"
    exit 1
else
    echo "[SUCCESS] Node.js 環境の検証が完了しました"
fi