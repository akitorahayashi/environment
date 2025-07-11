#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/.." && pwd )"

main() {
    setup_ruby_env
    
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
    
    # gemパッケージのインストール
    install_gem_packages "$gem_file"
    
    return 0
}

install_gem_packages() {
    local gem_file="$1"
    
    # すでにインストール済みかチェック
    if BUNDLE_GEMFILE="$gem_file" bundle check >/dev/null 2>&1; then
        echo "[OK] gems"
        return 0
    fi
    
    # gemをインストール
    echo "[INSTALL] gems"
    cd "$(dirname "$gem_file")" || {
        echo "[ERROR] Gemfileのディレクトリに移動できませんでした"
        return 1
    }
    
    if BUNDLE_GEMFILE="$gem_file" bundle install --quiet; then
        echo "[SUCCESS] Gemfileからgemのインストールが完了しました"
        echo "INSTALL_PERFORMED"
        return 0
    elif [ "${IS_CI:-false}" = "true" ]; then
        echo "[WARN] CI環境: gemインストールに問題がありますが続行します"
        return 0
    else
        echo "[ERROR] gemインストールに失敗しました"
        return 1
    fi
}

setup_ruby_env() {
    echo "==== Start: Ruby環境のセットアップを開始します..."
    
    # rbenvインストール
    install_rbenv || return 1
    
    # rbenvの初期化
    eval "$(rbenv init -)"
    
    # gemインストール（Rubyがある場合のみ実行）
    if command -v ruby; then
        install_gems
        echo "[INFO] Ruby環境: $(ruby -v) / $(gem -v) / $(bundle -v 2>/dev/null || echo 'bundler未インストール')"
    fi
    
    echo "[SUCCESS] Ruby環境のセットアップが完了しました"
}

verify_ruby_setup() {
    echo "==== Start: Ruby環境を検証中..."
    local errors=0
    
    # rbenvチェック
    verify_rbenv_installation || ((errors++))
    
    # Rubyチェック
    verify_ruby_installation
    
    # 検証結果
    if [ $errors -eq 0 ]; then
        echo "[SUCCESS] Ruby環境の検証が完了しました"
        return 0
    else
        echo "[ERROR] Ruby環境の検証に失敗しました ($errors エラー)"
        return 1
    fi
}

verify_rbenv_installation() {
    if ! command -v rbenv; then
        echo "[ERROR] rbenvコマンドが見つかりません"
        return 1
    fi
    
    echo "[SUCCESS] rbenv: $(rbenv --version)"
    
    # ruby-buildの確認
    if rbenv install --version >/dev/null 2>&1 || \
       command -v ruby-build || \
       [ -d "$(rbenv root)/plugins/ruby-build" ]; then
        echo "[SUCCESS] ruby-buildが使用可能です"
        return 0
    else
        echo "[ERROR] ruby-buildが見つかりません"
        return 1
    fi
}

verify_ruby_installation() {
    if ! command -v ruby; then
        echo "[INFO] Rubyはインストールされていません"
        return 0
    fi
    
    echo "[SUCCESS] Ruby: $(ruby -v)"
    
    # gemチェック
    if ! command -v gem; then
        echo "[ERROR] gemコマンドが見つかりません"
        return 1
    fi
    
    echo "[SUCCESS] gem: $(gem -v)"
    
    # bundlerチェック（任意）
    if command -v bundle; then
        echo "[SUCCESS] bundler: $(bundle -v)"
    else
        echo "[WARN] bundlerコマンドは利用できません（global-gems.rbがない場合は正常）"
    fi
    
    return 0
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi