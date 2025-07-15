#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    local ruby_version="3.3.0"

    echo "==== Start: Ruby環境のセットアップを開始します..."
    install_rbenv || exit 1
    eval "$(rbenv init -)"

    # Ruby 3.3.0がインストールされていなければインストール
    if ! rbenv versions --bare | grep -q "^${ruby_version}$"; then
        echo "[INSTALL] Ruby ${ruby_version}"
        rbenv install "${ruby_version}"
    else
        echo "[INFO] Ruby ${ruby_version} はすでにインストールされています"
    fi

    # グローバルバージョンを3.3.0に設定
    if [ "$(rbenv global)" != "${ruby_version}" ]; then
        echo "[CONFIG] rbenv global を ${ruby_version} に設定します"
        rbenv global "${ruby_version}"
    else
        echo "[INFO] rbenv global はすでに ${ruby_version} に設定されています"
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
        eval "$(rbenv init -)"
        return 0
    else
        echo "[ERROR] rbenvのインストールに失敗しました"
        exit 1
    fi
}

install_gems() {
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
    local ruby_version="3.3.0"

    # rbenvチェック
    if ! command -v rbenv >/dev/null 2>&1; then
        echo "[ERROR] rbenvコマンドが見つかりません"
        ((errors++))
    else
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
    if [ "$(rbenv version-name)" != "${ruby_version}" ]; then
        echo "[ERROR] Rubyのバージョンが${ruby_version}ではありません"
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