#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するRubyのバージョンを定数として定義
readonly RUBY_VERSION="3.3.0"

# 依存関係をインストール
echo "[INFO] 依存関係をチェック・インストールします: rbenv, ruby-build"
changed=false
if ! command -v rbenv &> /dev/null; then
    brew install rbenv ruby-build
    changed=true
fi
if [ "$changed" = true ]; then
    echo "IDEMPOTENCY_VIOLATION" >&2
fi

echo "==== Start: Ruby環境のセットアップを開始します..."

# rbenvを初期化して、以降のコマンドでrbenvのRubyが使われるようにする
eval "$(rbenv init -)"

changed=false
# Ruby 3.3.0がインストールされていなければインストール
if ! rbenv versions --bare | grep -q "^${RUBY_VERSION}$"; then
    echo "[INSTALL] Ruby ${RUBY_VERSION}"
    if ! rbenv install "${RUBY_VERSION}"; then
        echo "[ERROR] Ruby ${RUBY_VERSION} のインストールに失敗しました"
        exit 1
    fi
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
    gem_changed=false
    required_bundler_version=$(grep -E "gem[[:space:]]+['\"]bundler['\"]," "$gem_file" | grep -oE '[0-9.]+')
    if [ -z "$required_bundler_version" ]; then
        echo "[WARN] global-gems.rb にbundlerのバージョン指定が見つかりませんでした。通常のbundle installを試みます。"
        if ! command -v bundle >/dev/null 2>&1; then
            echo "[INSTALL] bundler"
            gem install bundler && rbenv rehash
            gem_changed=true
        fi
        (
            cd "$(dirname "$gem_file")" || exit 1
            BUNDLE_GEMFILE="$gem_file" bundle install --quiet
        )
    else
        echo "[INFO] 要求されているBundlerのバージョン: ${required_bundler_version}"
        if ! gem list bundler -i -v "$required_bundler_version" >/dev/null 2>&1; then
            echo "[INSTALL] bundler v${required_bundler_version} をインストールします"
            if ! gem install bundler -v "$required_bundler_version"; then
                echo "[ERROR] bundler v${required_bundler_version} のインストールに失敗しました"
                exit 1
            fi
            echo "[SUCCESS] bundler v${required_bundler_version} をインストールしました"
            gem_changed=true
            rbenv rehash
        else
            echo "[INFO] bundler v${required_bundler_version} はすでにインストールされています"
        fi
        bundler_cmd="bundle _${required_bundler_version}_"
        {
            cd "$(dirname "$gem_file")" || {
                echo "[ERROR] Gemfileのディレクトリに移動できませんでした: $(dirname "$gem_file")"
                exit 1
            }
            echo "[INFO] Gemfileからgemをチェック中 (using bundler v${required_bundler_version})..."
            if BUNDLE_GEMFILE="$gem_file" ${bundler_cmd} check >/dev/null 2>&1; then
                echo "[OK] 必要なgemはすべてインストール済みです"
            else
                echo "[INSTALL] gemをインストールします (using bundler v${required_bundler_version})..."
                if BUNDLE_GEMFILE="$gem_file" ${bundler_cmd} install --quiet; then
                    echo "[SUCCESS] Gemfileからgemのインストールが完了しました"
                    gem_changed=true
                    rbenv rehash
                else
                    echo "[ERROR] gemインストールに失敗しました"
                    exit 1
                fi
            fi
        }
    fi
    if [ "$gem_changed" = true ]; then
        echo "IDEMPOTENCY_VIOLATION" >&2
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
else
    echo "[SUCCESS] bundler: $(bundle -v)"
fi

echo "[SUCCESS] Ruby環境の検証が完了しました"
