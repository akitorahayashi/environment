#!/bin/bash

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
ENV_FILE="$2"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# 依存関係をインストール
echo "[INFO] Checking and installing dependencies: git"
changed=false
if ! command -v git &> /dev/null; then
    brew install git
    changed=true
fi

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

# Gitの設定ファイルのセットアップ
echo "[Start] Starting Git configuration file setup..."

mkdir -p "$HOME/.config/git"
src="$CONFIG_DIR_PROPS/git/.gitconfig"
dest="$HOME/.config/git/config"

# Only apply if missing or different
if [ ! -f "$dest" ] || ! cmp -s "$src" "$dest"; then
    if [ -f "$dest" ] || [ -L "$dest" ]; then
        echo "[INFO] Removing existing configuration file: $dest"
        rm -f "$dest"
    fi
    echo "        echo "[INFO] Copying Git configuration file...""
    if cp "$src" "$dest"; then
        echo "[SUCCESS] Gitの設定ファイルをコピーしました。"
    else
        echo "[ERROR] Git configuration file copy failed."
        exit 1
    fi
else
    echo "[INFO] Git configuration file is up to date. Skipping."
fi

# .envファイルからGitユーザー情報を設定
env_file="$ENV_FILE"
if [ -f "$env_file" ]; then
    echo "[INFO] .env file found. Loading Git user information..."

    # .envからキー=値のペアを直接読み込む (厳密なフォーマットを想定)
    GIT_USERNAME=$(grep "^GIT_USERNAME=" "$env_file" | cut -d'=' -f2)
    GIT_EMAIL=$(grep "^GIT_EMAIL=" "$env_file" | cut -d'=' -f2)

    # どちらか一方でも設定されていればそれを適用
    if [ -n "$GIT_USERNAME" ]; then
        git config --global user.name "$GIT_USERNAME"
        echo "[SUCCESS] Set user.name from .env."
    fi
    if [ -n "$GIT_EMAIL" ]; then
        git config --global user.email "$GIT_EMAIL"
        echo "[SUCCESS] Set user.email from .env."
    fi
fi

echo "[SUCCESS] Git configuration application completed"

# gitignore_globalのセットアップ
echo ""
echo "==== Start: Starting gitignore_global setup... ===="

ignore_file="$HOME/.gitignore_global"

# シンボリックリンクの作成
echo "[INFO] Creating gitignore_global symbolic link..."
if ln -sf "$CONFIG_DIR_PROPS/git/.gitignore_global" "$ignore_file"; then
    echo "[SUCCESS] gitignore_global symbolic link created."
else
    echo "[ERROR] gitignore_global のシンボリックリンク作成に失敗しました。"
    exit 1
fi

# Git に global gitignore を設定
echo "[INFO] Updating Git core.excludesfile..."
git config --global core.excludesfile "$ignore_file"
echo "[SUCCESS] Set global gitignore in Git core.excludesfile."

echo "[SUCCESS] gitignore_global setup completed"

echo "[SUCCESS] Git environment setup completed"

# Git設定の検証
echo ""
echo "==== Start: Verifying Git settings... ===="
verification_failed=false

# git コマンドの検証
if ! git --version >/dev/null 2>&1; then
    echo "[ERROR] git command not available"
    exit 1
fi
echo "[SUCCESS] git command available: $(git --version)"

# 設定ファイルの存在確認
if [ -f "$HOME/.config/git/config" ]; then
    echo "[SUCCESS] $HOME/.config/git/config exists."
else
    echo "[ERROR] $HOME/.config/git/config does not exist." >&2
    verification_failed=true
fi


# gitignore_global の検証
ignore_file="$HOME/.gitignore_global"
if [ ! -L "$ignore_file" ]; then
    echo "[ERROR] $ignore_file is not a symbolic link."
    verification_failed=true
fi

link_target=$(readlink "$ignore_file")
expected_target="$CONFIG_DIR_PROPS/git/.gitignore_global"

if [ "$link_target" = "$expected_target" ]; then
    echo "[SUCCESS] $ignore_file points to expected location"
else
    echo "[WARN] $ignore_file は期待されない場所を指しています: $link_target"
    verification_failed=true
fi

config_value=$(git config --global core.excludesfile 2>/dev/null)
if [ "$config_value" = "$ignore_file" ]; then
    echo "[SUCCESS] Git core.excludesfile is correctly set"
else
    echo "[ERROR] Git core.excludesfile is set to $config_value"
    verification_failed=true
fi

if [ "$verification_failed" = "true" ]; then
    echo "[ERROR] Git environment verification failed"
    exit 1
else
    echo "[SUCCESS] Git environment verification completed"
fi