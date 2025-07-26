#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

main() {
    echo "==== Start: macOS環境セットアップ - 事前準備 ===="
    echo ""
    echo "[INFO] このスクリプトは以下の作業を行います："
    echo "  1. Xcode Command Line Tools のインストール"
    echo "  2. 必要に応じたSSH鍵の生成"
    echo "  3. GitHubへのSSH鍵追加のガイド"
    echo "  4. SSH接続のテスト"
    echo "  5. 実行権限の付与"
    echo ""
    
    if ! ask_yes_no "続行しますか？"; then
        echo "[INFO] セットアップを中止します。"
        exit 0
    fi
    
    install_xcode_command_line_tools
    generate_ssh_key
    setup_public_key
    
    test_ssh_connection
    set_permissions
    
    echo -e "\n[SUCCESS] セットアップが完了しました！"
    echo ""
    echo "[INFO] 次のステップ："
    echo "  1. 以下のコマンドを実行してメインのセットアップを開始してください："
    echo "     ./install.sh"
    echo ""
    echo "  2. セットアップ完了後、ターミナルを再起動または以下を実行してください："
    echo "     source ~/.zprofile"
}

ask_yes_no() {
    local question=$1
    
    while true; do
        echo -n "$question [y/N]: "
        read -r answer
        
        case $answer in
            [Yy]|[Yy][Ee][Ss])
                return 0
                ;;
            [Nn]|[Nn][Oo]|"")
                return 1
                ;;
            *)
                echo "yまたはnで答えてください。"
                ;;
        esac
    done
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

install_xcode_command_line_tools() {
    echo -e "\n==== Start: Xcode Command Line Tools のインストール ===="
    
    if xcode-select -p &>/dev/null; then
        echo "[INFO] Xcode Command Line Tools は既にインストールされています"
    else
        echo "[INFO] Xcode Command Line Tools をインストールしています..."
        xcode-select --install
        
        while ! xcode-select -p &>/dev/null; do
            sleep 5
        done
        
        echo "[SUCCESS] Xcode Command Line Tools のインストールが完了しました"
    fi
}

generate_ssh_key() {
    echo -e "\n==== Start: SSH鍵の生成 ===="
    
    if [ -f ~/.ssh/id_ed25519 ]; then
        echo "[INFO] SSH鍵が既に存在します"
        echo "[SUCCESS] 既存のSSH鍵を使用します"
        return 0
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

setup_public_key() {
    echo -e "\n==== Start: GitHub SSH鍵の設定 ===="
    
    if [ ! -f ~/.ssh/id_ed25519.pub ]; then
        echo "[ERROR] 公開鍵ファイルが見つかりません"
        exit 1
    fi
    
    echo -e "[INFO] 以下の公開鍵をGitHubアカウントに追加してください：\n"
    echo "=== 公開鍵の内容 ==="
    cat ~/.ssh/id_ed25519.pub
    echo -e "=====================\n"
    
    if command -v pbcopy &> /dev/null; then
        cat ~/.ssh/id_ed25519.pub | pbcopy
        echo "[SUCCESS] 公開鍵がクリップボードにコピーされました"
    fi
    
    echo "Githubへの登録が完了した後にEnterキーを押してください、接続をテストします。"
    read -r
    
    echo "[SUCCESS] GitHub SSH鍵の設定完了"
}

test_ssh_connection() {
    echo -e "\n==== Start: SSH接続のテスト ===="
    
    echo "[INFO] GitHubへのSSH接続をテストしています..."
    
    if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
        echo "[SUCCESS] GitHubへのSSH接続が成功しました"
        return 0
    else
        echo -e "[ERROR] GitHubへのSSH接続に失敗しました\n[INFO] 以下の点を確認してください：\n  1. GitHubアカウントに公開鍵が正しく追加されているか\n  2. インターネット接続が正常か\n  3. ファイアウォール設定に問題がないか"
        
        if ask_yes_no "手動で再度テストしますか？"; then
            echo -e "[INFO] 以下のコマンドを実行してください：\n  ssh -T git@github.com\n\n[INFO] 成功すると以下のようなメッセージが表示されます：\n  Hi [ユーザー名]! You've successfully authenticated, but GitHub does not provide shell access."
        fi
        
        return 1
    fi
}

set_permissions() {
    echo -e "\n==== Start: 実行権限の付与 ===="
    
    echo "[INFO] セットアップスクリプトに実行権限を付与しています..."
    
    chmod +x "$SCRIPT_DIR/install.sh"
    find "$SCRIPT_DIR/scripts" -name "*.sh" -exec chmod +x {} \;
    
    echo "[SUCCESS] 実行権限が付与されました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi