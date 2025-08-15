#!/bin/bash

unset RBENV_VERSION

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

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

# .ruby-versionファイルからRubyのバージョンを読み込む
RUBY_VERSION_FILE="$REPO_ROOT/installers/config/ruby/.ruby-version"
if [ ! -f "$RUBY_VERSION_FILE" ]; then
    echo "[ERROR] .ruby-versionファイルが見つかりません: $RUBY_VERSION_FILE"
    exit 1
fi
readonly RUBY_VERSION=$(cat "$RUBY_VERSION_FILE" | tr -d '[:space:]')
if [ -z "$RUBY_VERSION" ]; then
    echo "[ERROR] .ruby-versionファイルからバージョンの読み込みに失敗しました。"
    exit 1
fi
echo "[INFO] .ruby-versionで指定されたRubyのバージョンは ${RUBY_VERSION} です。"

# 指定されたバージョンのRubyがインストールされていなければインストール
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

# グローバルバージョンを指定されたバージョンに設定
if [ "$(rbenv global)" != "${RUBY_VERSION}" ]; then
    echo "[CONFIG] rbenv global を ${RUBY_VERSION} に設定します"
    rbenv global "${RUBY_VERSION}"
    rbenv rehash
    changed=true
else
    echo "[INFO] rbenv global はすでに ${RUBY_VERSION} に設定されています"
fi

# gemのインストール処理
gem_file="${REPO_ROOT:-.}/installers/config/ruby/global-gems.rb"
if [ ! -f "$gem_file" ]; then
    echo "[INFO] global-gems.rbが見つかりません。gemのインストールをスキップします"
else
    readonly BUNDLER_VERSION="2.5.22"
    echo "[INFO] Bundlerのバージョンを確認しています... (必須: ${BUNDLER_VERSION})"
    current_version=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*' || echo "not-installed")

    if [ "$current_version" != "$BUNDLER_VERSION" ]; then
        echo "[INSTALL] Bundler v${BUNDLER_VERSION} をインストールします..."
        if gem install bundler -v "${BUNDLER_VERSION}" --no-document; then
            changed=true
        else
            echo "[ERROR] Bundler v${BUNDLER_VERSION} のインストールに失敗しました"
            exit 1
        fi
        rbenv rehash
    else
        echo "[INFO] Bundlerはすでにバージョン ${BUNDLER_VERSION} です"
    fi
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
    echo "[WARN] ruby-buildが見つかりません。インストールを試みます..."
    if brew install ruby-build; then
        echo "[SUCCESS] ruby-buildをインストールしました"
        changed=true
    else
        echo "[ERROR] ruby-build のインストールに失敗しました"
        exit 1
    fi
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

# bundlerのバージョンが指定通りであることを確認
readonly BUNDLER_VERSION_VERIFY="2.5.22"
current_version=$(bundle -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+(\.[a-zA-Z0-9]+)*' || echo "not-installed")

if [ "$current_version" != "$BUNDLER_VERSION_VERIFY" ]; then
    echo "[ERROR] bundlerのバージョンが異なります。期待: ${BUNDLER_VERSION_VERIFY}, 現在: ${current_version}"
    exit 1
else
    echo "[SUCCESS] bundler: $(bundle -v)"
fi

echo "[SUCCESS] Ruby環境の検証が完了しました"