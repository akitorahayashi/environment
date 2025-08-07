#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するRubyのバージョンを定数として定義
readonly RUBY_VERSION="3.3.0"

if [ -f "/home/linuxbrew/.linuxbrew/bin/brew" ]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
elif [ -f "/opt/homebrew/bin/brew" ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: rbenv, ruby-build"
if ! command -v rbenv &> /dev/null; then
    brew install rbenv ruby-build
fi

echo "==== Start: Ruby環境のセットアップを開始します..."

# rbenvを初期化して、以降のコマンドでrbenvのRubyが使われるようにする
eval "$(rbenv init -)"

# Ruby 3.3.0がインストールされていなければインストール
if ! rbenv versions --bare | grep -q "^${RUBY_VERSION}$"; then
    echo "[INSTALL] Ruby ${RUBY_VERSION}"
    export RUBY_CONFIGURE_OPTS="--with-openssl-dir=$(brew --prefix openssl)"
    if ! rbenv install "${RUBY_VERSION}"; then
        echo "[ERROR] Ruby ${RUBY_VERSION} のインストールに失敗しました"
        exit 1
    fi
    unset RUBY_CONFIGURE_OPTS
else
    echo "[INFO] Ruby ${RUBY_VERSION} はすでにインストールされています"
fi

# グローバルバージョンを3.3.0に設定
if [ "$(rbenv global)" != "${RUBY_VERSION}" ]; then
    echo "[CONFIG] rbenv global を ${RUBY_VERSION} に設定します"
    rbenv global "${RUBY_VERSION}"
    rbenv rehash
else
    echo "[INFO] rbenv global はすでに ${RUBY_VERSION} に設定されています"
fi

# gemのインストール処理
gem_file="${REPO_ROOT:-.}/config/gems/global-gems.rb"
if [ ! -f "$gem_file" ]; then
    echo "[INFO] global-gems.rbが見つかりません。gemのインストールをスキップします"
else
    echo "[INFO] Bundlerを最新バージョンに更新・インストールします..."
    gem install --no-document bundler
    rbenv rehash

    # Bundlerを使用してgemをインストール
    echo "[INFO] Bundlerを使ってgemをインストールします..."
    (
        cd "$(dirname "$gem_file")" || exit 1
        if ! bundle check --gemfile="$gem_file" >/dev/null 2>&1; then
            echo "[INSTALL] Gemfileからgemをインストールします..."
            if ! bundle install --gemfile="$gem_file" --quiet; then
                echo "[ERROR] gemのインストールに失敗しました"
                exit 1
            fi
            echo "[SUCCESS] gemのインストールが完了しました"
        else
            echo "[INFO] 必要なgemはすべてインストール済みです"
        fi
    )
fi

# 最終的な環境情報を表示
bundler_version=$(bundle -v 2>/dev/null || echo 'bundler未インストール')
echo "[INFO] Ruby環境: $(ruby -v) / $(gem -v) / ${bundler_version}"
echo "[SUCCESS] Ruby環境のセットアップが完了しました"

echo "==== Start: Ruby環境を検証中..."
# rbenvチェック
if ! command -v rbenv >/dev/null 2>&1; then
    echo "[ERROR] rbenvコマンドが見つかりません"
    exit 1
fi
# rbenvが関数としてロードされているか確認
if ! type rbenv | grep -q 'function'; then
    eval "$(rbenv init -)"
fi

echo "[SUCCESS] rbenv: $(rbenv --version)"
# ruby-buildの確認
if rbenv install --version >/dev/null 2>&1 || command -v ruby-build >/dev/null 2>&1 || [ -d "$(rbenv root)/plugins/ruby-build" ]; then
    echo "[SUCCESS] ruby-buildが使用可能です"
else
    echo "[ERROR] ruby-buildが見つかりません"
    exit 1
fi

# Rubyバージョンチェック
if [ "$(rbenv version-name)" != "${RUBY_VERSION}" ]; then
    echo "[ERROR] Rubyのバージョンが${RUBY_VERSION}ではありません"
    exit 1
else
    echo "[SUCCESS] Ruby: $(ruby -v)"
fi

# bundlerチェック
if ! command -v bundle >/dev/null 2>&1; then
    echo "[ERROR] bundlerコマンドが見つかりません"
    exit 1
fi

# bundlerのバージョンが最新であることを確認
latest_version_info=$(gem list --remote bundler --all | sort -V | tail -n 1)
latest_version=$(echo "$latest_version_info" | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*')
current_version=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*')

if [ "$current_version" != "$latest_version" ]; then
    echo "[WARN] bundlerのバージョンが最新ではありません。最新: ${latest_version}, 現在: ${current_version}"
else
    echo "[SUCCESS] bundler: $(bundle -v)"
fi

echo "[SUCCESS] Ruby環境の検証が完了しました"
