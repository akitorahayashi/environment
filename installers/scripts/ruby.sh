#!/bin/bash

set -euo pipefail

unset RBENV_VERSION

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 最新の安定版Rubyのバージョンを取得
echo "[INFO] 最新の安定版Rubyのバージョンを確認しています..."
LATEST_RUBY_VERSION=$(rbenv install -l | grep -E "^\s*[0-9]+\.[0-9]+\.[0-9]+$" | sort -V | tail -n 1 | tr -d ' ')
if [ -z "$LATEST_RUBY_VERSION" ]; then
    echo "[ERROR] 最新の安定版Rubyのバージョンが取得できませんでした。"
    exit 1
fi
readonly RUBY_VERSION="$LATEST_RUBY_VERSION"
echo "[INFO] 最新の安定版Rubyのバージョンは ${RUBY_VERSION} です。"


# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: rbenv, ruby-build"
changed=false
if ! command -v rbenv &> /dev/null; then
    brew install rbenv ruby-build
    changed=true
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
    changed=true
else
    echo "[INFO] Ruby ${RUBY_VERSION} はすでにインストールされています"
fi

# グローバルバージョンを3.3.0に設定
if [ "$(rbenv global)" != "${RUBY_VERSION}" ]; then
    echo "[CONFIG] rbenv global を ${RUBY_VERSION} に設定します"
    rbenv global "${RUBY_VERSION}"
    rbenv rehash
    changed=true
else
    echo "[INFO] rbenv global はすでに ${RUBY_VERSION} に設定されています"
fi

# gemのインストール処理
gem_file="${REPO_ROOT:-.}/config/gems/global-gems.rb"
if [ ! -f "$gem_file" ]; then
    echo "[INFO] global-gems.rbが見つかりません。gemのインストールをスキップします"
else
    echo "[INFO] Bundlerを最新バージョンに更新・インストールします..."
    gem_install_output=$(gem install --no-document bundler)
    if echo "$gem_install_output" | grep -q "gem installed"; then
        changed=true
    fi
    rbenv rehash

fi

# 最終的な環境情報を表示
bundler_version=$(bundle -v 2>/dev/null || echo 'bundler未インストール')
echo "[INFO] Ruby環境: $(ruby -v) / $(gem -v) / ${bundler_version}"
echo "[SUCCESS] Ruby環境のセットアップが完了しました"

if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

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
