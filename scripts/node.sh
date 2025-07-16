#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    echo "[Start] Node.js のセットアップを開始します..."

    # Node.js のインストール確認
    if ! command -v node; then
        echo "[WARN] Node.js がインストールされていません。Brewfileを確認してください。"
        exit 1
    fi
    echo "[SUCCESS] Node.js はすでにインストールされています"

    # npm のインストール確認
    if ! command -v npm; then
        echo "[WARN] npm がインストールされていません。Node.js のインストールを確認してください。"
        exit 1
    fi
    echo "[OK] npm はすでにインストールされています"

    # グローバルパッケージのインストール
    install_global_packages

    echo "[SUCCESS] Node.js 環境のセットアップが完了しました"

    verify_node_setup
}

install_global_packages() {
    local packages_file="$REPO_ROOT/config/node/global-packages.json"
    
    if [ ! -f "$packages_file" ]; then
        echo "[WARN] global-packages.json が見つかりません。グローバルパッケージのインストールをスキップします"
        return 0
    fi
    
    echo "[INFO] グローバルパッケージをチェック中..."
    
    # JSONファイルからキー（パッケージ名）とバージョンを読み込み "name@version" の配列を作成
    local entries=($(jq -r '.globalPackages | to_entries[] | "\(.key)@\(.value)"' "$packages_file" 2>/dev/null))
    
    if [ ${#entries[@]} -eq 0 ]; then
        echo "[WARN] global-packages.json にパッケージが定義されていません"
        return 0
    fi
    
    # 各 "name@version" を分割してインストール
    for entry in "${entries[@]}"; do
        # pkg_full: "name@version" 例: "@anthropic-ai/claude-code@latest"
        pkg_full="$entry"
        # pkg_name: entry から最終の "@バージョン" を取り除く
        pkg_name="${entry%@*}"
        
        if npm list -g "$pkg_name" &>/dev/null; then
            echo "[INSTALLED] $pkg_name"
        else
            echo "[INSTALLING] $pkg_full"
            echo "INSTALL_PERFORMED"
            if npm install -g "$pkg_full"; then
                echo "[SUCCESS] $pkg_name のインストールが完了しました"
            else
                echo "[ERROR] $pkg_name のインストールに失敗しました"
                exit 1
            fi
        fi
    done
    
    return 0
}

verify_node_setup() {
    echo ""
    echo "==== Start: Node.js 環境を検証中... ===="
    local verification_failed=false
    
    # Node.js と npm の確認は setup 関数の後に実行されるため、既にインストールされているはず
    echo "[SUCCESS] Node.js: $(node --version)"
    echo "[SUCCESS] npm: $(npm --version)"
    
    # グローバルパッケージの確認
    verify_global_packages || verification_failed=true
    
    if [ "$verification_failed" = "true" ]; then
        echo "[ERROR] Node.js 環境の検証に失敗しました"
        return 1
    else
        echo "[SUCCESS] Node.js 環境の検証が完了しました"
        return 0
    fi
}

verify_global_packages() {
    local packages_file="$REPO_ROOT/config/node/global-packages.json"
    
    if [ ! -f "$packages_file" ]; then
        echo "[WARN] global-packages.json が見つかりません"
        return 0
    fi
    
    local packages=($(jq -r '.globalPackages | to_entries[] | "\(.key)"' "$packages_file" 2>/dev/null))
    local missing=0
    
    for package in "${packages[@]}"; do
        if ! npm list -g "$package" &>/dev/null; then
            echo "[ERROR] グローバルパッケージ $package がインストールされていません"
            ((missing++))
        else
            echo "[SUCCESS] グローバルパッケージ $package がインストールされています"
        fi
    done
    
    if [ $missing -gt 0 ]; then
        return 1
    fi
    
    return 0
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi