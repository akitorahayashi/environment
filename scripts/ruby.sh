#!/bin/bash

set -euo pipefail

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するRubyのバージョンを定数として定義
readonly RUBY_VERSION="3.3.0"

main() {
    echo "==== Start: Ruby環境のセットアップを開始します..."
    install_rbenv || exit 1

    # rbenvを初期化して、以降のコマンドでrbenvのRubyが使われるようにする
    eval "$(rbenv init -)"

    # Ruby 3.3.0がインストールされていなければインストール
    if ! rbenv versions --bare | grep -q "^${RUBY_VERSION}$"; then
        echo "[INSTALL] Ruby ${RUBY_VERSION}"
        if ! rbenv install "${RUBY_VERSION}"; then
            echo "[ERROR] Ruby ${RUBY_VERSION} のインストールに失敗しました"
            exit 1
        fi
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
    install_gems || exit 1

    # 最終的な環境情報を表示
    local bundler_version
    bundler_version=$(bundle -v 2>/dev/null || echo 'bundler未インストール')
    echo "[INFO] Ruby環境: $(ruby -v) / $(gem -v) / ${bundler_version}"
    echo "[SUCCESS] Ruby環境のセットアップが完了しました"

    verify_ruby_setup
}

# rbenvのインストール
install_rbenv() {
    if command -v rbenv >/dev/null 2>&1; then
        echo "[SUCCESS] rbenv はインストール済みです"
        return 0
    fi
    echo "[INSTALL] rbenv"
    if brew install rbenv ruby-build; then
        echo "[SUCCESS] rbenvのインストールが完了しました"
        echo "INSTALL_PERFORMED"
        return 0
    else
        echo "[ERROR] rbenvのインストールに失敗しました"
        exit 1
    fi
}

# gemのインストール（Bundlerのバージョン問題を修正）
install_gems() {
    local gem_file="${REPO_ROOT:-.}/config/gems/global-gems.rb"
    if [ ! -f "$gem_file" ]; then
        echo "[INFO] global-gems.rbが見つかりません。gemのインストールをスキップします"
        return 0
    fi

    # global-gems.rbからbundlerのバージョンを抽出（シングル/ダブルクォート両対応に修正）
    local required_bundler_version
    required_bundler_version=$(grep -E "gem[[:space:]]+['\"]bundler['\"]," "$gem_file" | grep -oE '[0-9.]+')

    if [ -z "$required_bundler_version" ]; then
        echo "[WARN] global-gems.rb にbundlerのバージョン指定が見つかりませんでした。通常のbundle installを試みます。"
        # bundlerバージョン指定がなければ従来通り
        if ! command -v bundle >/dev/null 2>&1; then
            echo "[INSTALL] bundler"
            gem install bundler && rbenv rehash
        fi
        (
            cd "$(dirname "$gem_file")" || return 1
            BUNDLE_GEMFILE="$gem_file" bundle install --quiet
        )
        return $?
    fi

    echo "[INFO] 要求されているBundlerのバージョン: ${required_bundler_version}"

    # 必要なバージョンのBundlerがインストールされているか確認
    if ! gem list bundler -i -v "$required_bundler_version" >/dev/null 2>&1; then
        echo "[INSTALL] bundler v${required_bundler_version} をインストールします"
        # gem installは冪等なので、既に存在していてもエラーにならない
        if ! gem install bundler -v "$required_bundler_version"; then
            echo "[ERROR] bundler v${required_bundler_version} のインストールに失敗しました"
            return 1
        fi
        echo "[SUCCESS] bundler v${required_bundler_version} をインストールしました"
        echo "INSTALL_PERFORMED" # 冪等性チェックのため追加
        rbenv rehash
    else
        echo "[INFO] bundler v${required_bundler_version} はすでにインストールされています"
    fi

    # 特定バージョンのBundlerコマンドを定義
    local bundler_cmd="bundle _${required_bundler_version}_"

    (
        cd "$(dirname "$gem_file")" || {
            echo "[ERROR] Gemfileのディレクトリに移動できませんでした: $(dirname "$gem_file")"
            return 1
        }

        echo "[INFO] Gemfileからgemをチェック中 (using bundler v${required_bundler_version})..."
        # 特定バージョンのBundlerでチェック
        if BUNDLE_GEMFILE="$gem_file" ${bundler_cmd} check >/dev/null 2>&1; then
            echo "[OK] 必要なgemはすべてインストール済みです"
            return 0
        fi

        echo "[INSTALL] gemをインストールします (using bundler v${required_bundler_version})..."
        # 特定バージョンのBundlerでインストール
        if BUNDLE_GEMFILE="$gem_file" ${bundler_cmd} install --quiet; then
            echo "[SUCCESS] Gemfileからgemのインストールが完了しました"
            echo "INSTALL_PERFORMED"
            rbenv rehash
        else
            echo "[ERROR] gemインストールに失敗しました"
            # CI環境での警告は削除し、常にエラーとして扱う
            return 1
        fi
    )
}

verify_ruby_setup() {
    echo "==== Start: Ruby環境を検証中..."
    # rbenvチェック
    if ! command -v rbenv >/dev/null 2>&1; then
        echo "[ERROR] rbenvコマンドが見つかりません"
        return 1
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
        return 1
    fi

    # Rubyバージョンチェック
    if [ "$(rbenv version-name)" != "${RUBY_VERSION}" ]; then
        echo "[ERROR] Rubyのバージョンが${RUBY_VERSION}ではありません"
        return 1
    else
        echo "[SUCCESS] Ruby: $(ruby -v)"
    fi

    # bundlerチェック
    if ! command -v bundle >/dev/null 2>&1; then
        echo "[ERROR] bundlerコマンドが見つかりません"
        return 1
    else
        echo "[SUCCESS] bundler: $(bundle -v)"
    fi

    echo "[SUCCESS] Ruby環境の検証が完了しました"
    return 0
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
