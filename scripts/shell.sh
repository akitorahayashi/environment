#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

echo "[Start] シェル設定ファイルのセットアップを開始します..."

# シンボリックリンクの作成
echo "[INFO] シェル設定ファイルのシンボリックリンクを作成します..."
if ln -sf "$REPO_ROOT/config/shell/.zprofile" "$HOME/.zprofile"; then
    echo "[SUCCESS] .zprofile のシンボリックリンクを作成しました。"
else
    echo "[ERROR] .zprofile のシンボリックリンク作成に失敗しました。"
    exit 1
fi
if ln -sf "$REPO_ROOT/config/shell/.zshrc" "$HOME/.zshrc"; then
    echo "[SUCCESS] .zshrc のシンボリックリンクを作成しました。"
else
    echo "[ERROR] .zshrc のシンボリックリンク作成に失敗しました。"
    exit 1
fi

echo "[SUCCESS] シェル環境のセットアップが完了しました"

echo "[Start] シェル設定を検証中..."
verification_failed=false

# .zprofile の検証
if [ ! -L "$HOME/.zprofile" ]; then
    echo "[ERROR] .zprofile がシンボリックリンクではありません"
    verification_failed=true
else
    link_target=$(readlink "$HOME/.zprofile")
    expected_target="$REPO_ROOT/config/shell/.zprofile"
    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] .zprofile がシンボリックリンクとして存在し、期待される場所を指しています"
    else
        echo "[WARN] .zprofile はシンボリックリンクですが、期待しない場所を指しています:"
        echo "[WARN]   期待: $expected_target"
        echo "[WARN]   実際: $link_target"
        verification_failed=true
    fi
fi

# .zshrc の検証
if [ ! -L "$HOME/.zshrc" ]; then
    echo "[ERROR] .zshrc がシンボリックリンクではありません"
    verification_failed=true
else
    link_target=$(readlink "$HOME/.zshrc")
    expected_target="$REPO_ROOT/config/shell/.zshrc"
    if [ "$link_target" = "$expected_target" ]; then
        echo "[SUCCESS] .zshrc がシンボリックリンクとして存在し、期待される場所を指しています"
    else
        echo "[WARN] .zshrc はシンボリックリンクですが、期待しない場所を指しています:"
        echo "[WARN]   期待: $expected_target"
        echo "[WARN]   実際: $link_target"
        verification_failed=true
    fi
fi

# PATH環境変数の検証
if [ -z "$PATH" ]; then
    echo "[ERROR] PATH環境変数が設定されていません"
    verification_failed=true
else
    echo "[SUCCESS] PATH環境変数が設定されています"
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] シェル設定の検証に失敗しました"
    exit 1
else
    echo "[SUCCESS] シェル設定の検証が正常に完了しました"
fi