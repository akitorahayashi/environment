#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

# 使用するRubyのバージョンを定数として定義
readonly RUBY_VERSION="3.3.0"

main() {

    echo "==== Start: Ruby環境のセットアップを開始します..."
    install_rbenv || exit 1
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

    install_gems
    echo "[INFO] Ruby環境: $(ruby -v) / $(gem -v) / $(bundle -v 2>/dev/null || echo 'bundler未インストール')"
    echo "[SUCCESS] Ruby環境のセットアップが完了しました"
}

install_rbenv() {
    if command -v rbenv; then
        echo "[SUCCESS] rbenv"
        return 0
    fi
    echo "[INSTALL] rbenv"
    echo "INSTALL_PERFORMED"
    if brew install rbenv ruby-build; then
        echo "[SUCCESS] rbenvのインストールが完了しました"
        return 0
    else
        echo "[ERROR] rbenvのインストールに失敗しました"
        exit 1
    fi
}

install_gems() {
    if ! command -v bundle >/dev/null 2>&1; then
        echo "[ERROR] bundler が見つかりません。gem install bundler を実行してください"
        return 1
    fi
    local gem_file="${REPO_ROOT:-$ROOT_DIR}/config/gems/global-gems.rb"
    if [ ! -f "$gem_file" ]; then
        echo "[INFO] global-gems.rbが見つかりません。gemのインストールをスキップします"
        return 0
    fi
    echo "[INFO] Gemfileからgemをチェック中..."
    if BUNDLE_GEMFILE="$gem_file" bundle check >/dev/null 2>&1; then
        echo "[OK] gems"
        return 0
    fi
    echo "[INSTALL] gems"
    cd "$(dirname "$gem_file")" || {
        echo "[ERROR] Gemfileのディレクトリに移動できませんでした"
        return 1
    }
    if BUNDLE_GEMFILE="$gem_file" bundle install --quiet; then
        echo "[SUCCESS] Gemfileからgemのインストールが完了しました"
        echo "INSTALL_PERFORMED"
        rbenv rehash
    elif [ "${IS_CI:-false}" = "true" ]; then
        echo "[WARN] CI環境: gemインストールに問題がありますが続行します"
    else
        echo "[ERROR] gemインストールに失敗しました"
        return 1
    fi
}

verify_ruby_setup() {
    echo "==== Start: Ruby環境を検証中..."
    local errors=0

    # rbenvチェック
    if ! command -v rbenv >/dev/null 2>&1; then
        echo "[ERROR] rbenvコマンドが見つかりません"
        ((errors++))
    else
        eval "$(rbenv init -)"
        echo "[SUCCESS] rbenv: $(rbenv --version)"
        # ruby-buildの確認
        if rbenv install --version >/dev/null 2>&1 || command -v ruby-build >/dev/null 2>&1 || [ -d "$(rbenv root)/plugins/ruby-build" ]; then
            echo "[SUCCESS] ruby-buildが使用可能です"
        else
            echo "[ERROR] ruby-buildが見つかりません"
            ((errors++))
        fi
    fi

    # Rubyバージョンチェック
    if [ "$(rbenv version-name)" != "${RUBY_VERSION}" ]; then
        echo "[ERROR] Rubyのバージョンが${RUBY_VERSION}ではありません"
        ((errors++))
    else
        echo "[SUCCESS] Ruby: $(ruby -v)"
    fi

    # bundlerチェック
    if ! command -v bundle >/dev/null 2>&1; then
        echo "[ERROR] bundlerコマンドが見つかりません"
        ((errors++))
    else
        echo "[SUCCESS] bundler: $(bundle -v)"
    fi

    # 検証結果
    if [ $errors -eq 0 ]; then
        echo "[SUCCESS] Ruby環境の検証が完了しました"
        return 0
    else
        echo "[ERROR] Ruby環境の検証に失敗しました ($errors エラー)"
        return 1
    fi
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi