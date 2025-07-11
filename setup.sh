#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# エラー発生時に即座に終了する設定
set -e

main() {
    echo "==== Start: macOS環境セットアップ - 事前準備 ===="
    
    echo "[INFO] このスクリプトは以下の作業を行います："
    echo "  1. 依存関係のチェック"
    echo "  2. 必要に応じたSSH鍵の生成"
    echo "  3. GitHubへのSSH鍵追加のガイド"
    echo "  4. SSH接続のテスト"
    echo "  5. 実行権限の付与"
    echo ""
    
    if ! ask_yes_no "続行しますか？"; then
        echo "[INFO] セットアップを中止します。"
        exit 0
    fi
    
    confirm_user_info
    check_dependencies
    generate_ssh_key
    show_public_key
    test_ssh_connection
    set_permissions
    
    echo "[SUCCESS] セットアップが完了しました！"
    echo "[INFO] 次のステップ："
    echo "  1. 以下のコマンドを実行してメインのセットアップを開始してください："
    echo "     ./install.sh"
    echo "  2. セットアップ完了後、ターミナルを再起動または以下を実行してください："
    echo "     source ~/.zprofile"
    echo "[WARN] 注意: install.shの実行には時間がかかる場合があります。"
}

ask_yes_no() {
    local question=$1
    local default=${2:-"n"}
    
    [ "$default" = "y" ] && echo -n "$question [Y/n]: " || echo -n "$question [y/N]: "
    read -r answer
    [ -z "$answer" ] && answer=$default
    
    case $answer in
        [Yy]*) return 0 ;;
        [Nn]*) return 1 ;;
        *) 
            echo "[ERROR] 無効な入力です。スクリプトを終了します。"
            exit 1
            ;;
    esac
}

get_email() {
    while true; do
        echo -n "GitHubで使用しているメールアドレスを入力してください: "
        read -r email
        
        if [ -z "$email" ]; then
            echo "[ERROR] メールアドレスが入力されていません。"
            continue
        fi
        
        if [[ "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
            echo "$email"
            return 0
        else
            echo "[ERROR] 有効なメールアドレスを入力してください。"
        fi
    done
}

confirm_user_info() {
    echo ""
    echo "==== Start: ユーザー情報の確認 ===="
    
    local current_user=$(whoami)
    local current_dir=$(pwd)
    
    echo "[INFO] 現在のユーザー: $current_user"
    echo "[INFO] 現在のディレクトリ: $current_dir"
    echo "[INFO] スクリプトディレクトリ: $SCRIPT_DIR"
    
    if ! ask_yes_no "この情報で続行しますか？"; then
        echo "[INFO] セットアップを中止します。"
        exit 0
    fi
    
    echo "[SUCCESS] ユーザー情報の確認完了"
}

check_dependencies() {
    echo ""
    echo "==== Start: 依存関係のチェック ===="
    
    local missing_deps=()
    
    if ! command -v git &> /dev/null; then
        missing_deps+=("git")
    fi
    
    if ! command -v ssh &> /dev/null; then
        missing_deps+=("ssh")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "[ERROR] 以下のコマンドが見つかりません："
        for dep in "${missing_deps[@]}"; do
            echo "  - $dep"
        done
        echo "[INFO] Xcode Command Line Toolsをインストールしてください："
        echo "  xcode-select --install"
        exit 2
    fi
    
    echo "[SUCCESS] 必要な依存関係が揃っています"
}

generate_ssh_key() {
    echo ""
    echo "==== Start: SSH鍵の生成 ===="
    
    if [ -f ~/.ssh/id_ed25519 ]; then
        echo "[INFO] SSH鍵が既に存在します"
        if ask_yes_no "既存のSSH鍵を使用しますか？"; then
            echo "[SUCCESS] 既存のSSH鍵を使用します"
            return 0
        fi
    else
        echo "[INFO] SSH鍵が見つかりません"
    fi
    
    local email
    email=$(get_email)
    
    echo "[INFO] SSH鍵を生成しています..."
    ssh-keygen -t ed25519 -C "$email" -f ~/.ssh/id_ed25519 -N ""
    
    eval "$(ssh-agent -s)"
    ssh-add ~/.ssh/id_ed25519
    
    echo "[SUCCESS] SSH鍵が生成されました"
}

show_public_key() {
    echo ""
    echo "==== Start: GitHub SSH鍵の設定 ===="
    
    if [ ! -f ~/.ssh/id_ed25519.pub ]; then
        echo "[ERROR] 公開鍵ファイルが見つかりません"
        exit 2
    fi
    
    echo "[INFO] 以下の公開鍵をGitHubアカウントに追加してください："
    echo ""
    echo "=== 公開鍵の内容 ==="
    cat ~/.ssh/id_ed25519.pub
    echo "====================="
    echo ""
    
    echo "[INFO] GitHubでの設定手順："
    echo "  1. GitHub.comにログインして、右上のプロフィール画像をクリック"
    echo "  2. 'Settings' を選択"
    echo "  3. 左側のメニューから 'SSH and GPG keys' を選択"
    echo "  4. 'New SSH key' をクリック"
    echo "  5. Title に適当な名前を入力（例：MacBook Pro）"
    echo "  6. 上記の公開鍵をKey欄に貼り付け"
    echo "  7. 'Add SSH key' をクリック"
    echo ""
    
    if command -v pbcopy &> /dev/null; then
        cat ~/.ssh/id_ed25519.pub | pbcopy
        echo "[SUCCESS] 公開鍵がクリップボードにコピーされました"
    fi
    
    echo "準備ができたらEnterキーを押してください..."
    read -r
    
    echo "[SUCCESS] GitHub SSH鍵の設定完了"
}

test_ssh_connection() {
    echo ""
    echo "==== Start: SSH接続のテスト ===="
    
    echo "[INFO] GitHubへのSSH接続をテストしています..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "[SUCCESS] GitHubへのSSH接続が成功しました"
        return 0
    else
        echo "[ERROR] GitHubへのSSH接続に失敗しました"
        echo "[INFO] 以下の点を確認してください："
        echo "  1. GitHubアカウントに公開鍵が正しく追加されているか"
        echo "  2. インターネット接続が正常か"
        echo "  3. ファイアウォール設定に問題がないか"
        
        if ask_yes_no "手動で再度テストしますか？"; then
            echo "[INFO] 以下のコマンドを実行してください："
            echo "  ssh -T git@github.com"
            echo ""
            echo "[INFO] 成功すると以下のようなメッセージが表示されます："
            echo "  Hi [ユーザー名]! You've successfully authenticated, but GitHub does not provide shell access."
        fi
        
        return 1
    fi
}

set_permissions() {
    echo ""
    echo "==== Start: 実行権限の付与 ===="
    
    echo "[INFO] セットアップスクリプトに実行権限を付与しています..."
    
    chmod +x "$SCRIPT_DIR/install.sh"
    find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    
    echo "[SUCCESS] 実行権限が付与されました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
