#!/bin/bash

# スクリプトの引数から設定ディレクトリのパスを取得
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

if [ -z "${REPO_ROOT:-}" ]; then
    echo "[ERROR] REPO_ROOT environment variable is not set. This script should be run via 'make'." >&2
    exit 1
fi

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: git"
changed=false
if ! command -v git &> /dev/null; then
    brew install git
    changed=true
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# Gitの設定ファイルのセットアップ
echo "[Start] Gitの設定ファイルのセットアップを開始します..."

mkdir -p "$HOME/.config/git"
src="$REPO_ROOT/$CONFIG_DIR_PROPS/git/.gitconfig"
dest="$HOME/.config/git/config"

# Only apply if missing or different
if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        echo "[INFO] 既存の設定ファイルを削除します: $dest"
        rm -f "$dest"
    fi
    echo "[INFO] Gitの設定ファイルをコピーします..."
    if cp "$src" "$dest"; then
        echo "[SUCCESS] Gitの設定ファイルをコピーしました。"
    else
        echo "[ERROR] Gitの設定ファイルのコピーに失敗しました。"
        exit 1
    fi
else
    echo "[INFO] Gitの設定ファイルは最新です。スキップします。"
fi

# .envファイルからGitユーザー情報を設定
env_file="$REPO_ROOT/.env"
if [ -f "$env_file" ]; then
    echo "[INFO] .envファイルが見つかりました。Gitユーザー情報を読み込みます..."

    # .envからキー=値のペアを直接読み込む (厳密なフォーマットを想定)
    GIT_USERNAME=$(grep "^GIT_USERNAME=" "$env_file" | cut -d'=' -f2)
    GIT_EMAIL=$(grep "^GIT_EMAIL=" "$env_file" | cut -d'=' -f2)

    # どちらか一方でも設定されていればそれを適用
    if [ -n "$GIT_USERNAME" ]; then
        git config --global user.name "$GIT_USERNAME"
        echo "[SUCCESS] .env から user.name を設定しました。"
    fi
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        echo "[SUCCESS] .env から user.email を設定しました。"
    fi
fi

echo "[SUCCESS] Git の設定適用完了"

# gitignore_globalのセットアップ
echo ""
echo "==== Start: gitignore_globalのセットアップを開始します... ===="

ignore_file="$HOME/.gitignore_global"

# シンボリックリンクの作成
echo "[INFO] gitignore_global のシンボリックリンクを作成します..."
if ln -sf "$REPO_ROOT/$CONFIG_DIR_PROPS/git/.gitignore_global" "$ignore_file"; then
    echo "[SUCCESS] gitignore_global のシンボリックリンクを作成しました。"
else
    echo "[ERROR] gitignore_global のシンボリックリンク作成に失敗しました。"
    exit 1
fi

# Git に global gitignore を設定
echo "[INFO] Git の core.excludesfile を更新しています..."
git config --global core.excludesfile "$ignore_file"
echo "[SUCCESS] Git の core.excludesfile に global gitignore を設定しました。"

echo "[SUCCESS] gitignore_global の設定完了"

echo "[SUCCESS] Git環境のセットアップが完了しました"

# Git設定の検証
echo ""
echo "==== Start: Git設定を検証中... ===="
verification_failed=false

# git コマンドの検証
if ! git --version >/dev/null 2>&1; then
    echo "[ERROR] gitコマンドが使用できません"
    exit 1
fi
echo "[SUCCESS] gitコマンドが使用可能です: $(git --version)"

# 設定ファイルの存在確認
echo "[SUCCESS] $HOME/.config/git/config が存在します。"


# gitignore_global の検証
ignore_file="$HOME/.gitignore_global"
if [ ! -L "$ignore_file" ]; then
    echo "[ERROR] $ignore_file がシンボリックリンクではありません。"
    verification_failed=true
fi

link_target=$(readlink "$ignore_file")
expected_target="$REPO_ROOT/$CONFIG_DIR_PROPS/git/.gitignore_global"

if [ "$link_target" = "$expected_target" ]; then
    echo "[SUCCESS] $ignore_file が期待される場所を指しています"
else
    echo "[WARN] $ignore_file は期待されない場所を指しています: $link_target"
    verification_failed=true
fi

config_value=$(git config --global core.excludesfile 2>/dev/null)
if [ "$config_value" = "$ignore_file" ]; then
    echo "[SUCCESS] Git の core.excludesfile が正しく設定されています"
else
    echo "[ERROR] Git の core.excludesfile が $config_value になっています"
    verification_failed=true
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Git環境の検証に失敗しました"
    exit 1
else
    echo "[SUCCESS] Git環境の検証が完了しました"
fi