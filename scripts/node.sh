#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するNode.jsのバージョンを定数として定義
readonly NODE_VERSION="22.17.1"

# 依存関係をインストール
install_dependencies() {
    echo "[INFO] 依存関係をチェック・インストールします: nvm, jq"
    local changed=false
    if ! command -v nvm &> /dev/null; then
        brew install nvm
        changed=true
    fi
    if ! command -v jq &> /dev/null; then
        brew install jq
        changed=true
    fi

    if [ "$changed" = true ]; then
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi
}

# nvmを初期化
source_nvm() {
    if [ -s "$(brew --prefix nvm)/nvm.sh" ]; then
        # shellcheck source=/dev/null
        . "$(brew --prefix nvm)/nvm.sh"
    else
        echo "[ERROR] nvm.sh が見つかりません。nvm のインストールを確認してください"
        exit 1
    fi
}

# 特定のNode.jsバージョンをインストール
install_node() {
    source_nvm
    local changed=false

    # 特定のバージョンがインストールされているか確認
    if ! nvm ls "$NODE_VERSION" | grep -q "$NODE_VERSION"; then
        echo "[INSTALLING] Node.js $NODE_VERSION をインストールします..."
        if nvm install "$NODE_VERSION"; then
            echo "[SUCCESS] Node.js $NODE_VERSION のインストールが完了しました"
            changed=true
        else
            echo "[ERROR] Node.js $NODE_VERSION のインストールに失敗しました"
            exit 1
        fi
    else
        echo "[INSTALLED] Node.js $NODE_VERSION はすでにインストールされています"
    fi

    if [ "$changed" = true ]; then
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi
}


main() {
    install_dependencies
    echo "[Start] Node.js のセットアップを開始します..."

    # nvm経由でNode.jsをインストール
    install_node

    # nvm環境を読み込む
    source_nvm
    nvm use "$NODE_VERSION" > /dev/null # ターミナルの出力なし

    # npm のインストール確認
    if ! command -v npm &> /dev/null; then
        echo "[ERROR] npm が見つかりません。nvm の設定と Node.js のインストールを確認してください。"
        exit 1
    fi
    echo "[OK] npm は利用可能です"

    # グローバルパッケージのインストール
    install_global_packages

    echo "[SUCCESS] Node.js 環境のセットアップが完了しました"

    # macOS のみ環境検証を実行
    if [[ "$(uname)" == "Darwin" ]]; then
        verify_node_setup
    else
        echo "[INFO] macOS以外の環境のため、環境検証をスキップします"
    fi
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
    
    local changed=false
    # 各 "name@version" を分割してインストール
    for entry in "${entries[@]}"; do
        # pkg_full: "name@version" 例: "@anthropic-ai/claude-code@latest"
        pkg_full="$entry"
        # pkg_name: entry から最終の "@バージョン" を取り除く
        pkg_name="${entry%@*}"
        
        installed_version=$(npm list -g --depth=0 "$pkg_name" | grep -E "$pkg_name@[0-9]" | awk -F'@' '{print $NF}')
        required_version=$(echo "$pkg_full" | awk -F'@' '{print $NF}')

        # バージョンが 'latest' の場合は単純な存在チェックにフォールバック
        if [ "$required_version" == "latest" ]; then
            if [ -z "$installed_version" ]; then
                echo "[INSTALLING] $pkg_full"
                if npm install -g "$pkg_full"; then
                    echo "[SUCCESS] $pkg_name のインストールが完了しました"
                    changed=true
                else
                    echo "[ERROR] $pkg_name のインストールに失敗しました"
                    exit 1
                fi
            else
                echo "[INSTALLED] $pkg_name (latest)"
            fi
        # バージョンが指定されていて、インストールされているバージョンと異なる場合
        elif [ "$installed_version" != "$required_version" ]; then
            echo "[UPDATING] $pkg_full (found: $installed_version)"
            if npm install -g "$pkg_full"; then
                echo "[SUCCESS] $pkg_name の更新が完了しました"
                changed=true
            else
                echo "[ERROR] $pkg_name の更新に失敗しました"
                exit 1
            fi
        else
            echo "[INSTALLED] $pkg_name"
        fi
    done
    
    if [ "$changed" = true ]; then
        echo "IDEMPOTENCY_VIOLATION" >&2
    fi

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