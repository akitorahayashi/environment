#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# rbenvをインストール
install_rbenv() {
    if command_exists rbenv; then
        log_installed "rbenv"
        return 0
    fi
    
    log_installing "rbenv"
    if brew install rbenv ruby-build; then
        log_success "rbenvのインストールが完了しました"
        eval "$(rbenv init -)"
        return 0
    else
        handle_error "rbenvのインストールに失敗しました"
        return 1
    fi
}

# Gemfileからgemをインストール
install_gems() {
    local gem_file="${REPO_ROOT:-$ROOT_DIR}/config/gems/global-gems.rb"
    
    if [ ! -f "$gem_file" ]; then
        log_info "global-gems.rbが見つかりません。gemのインストールをスキップします"
        return 0
    fi
    
    log_info "Gemfileからgemをチェック中..."
    
    # bundlerの確認とインストール
    install_bundler_if_needed "$gem_file"
    
    # gemパッケージのインストール
    install_gem_packages "$gem_file"
    
    return 0
}

# bundlerの確認とインストール
install_bundler_if_needed() {
    local gem_file="$1"
    
    if command_exists bundle; then
        # 既存のbundlerバージョンを確認
        local current_version=$(bundle --version | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' || echo "unknown")
        log_installed "bundler" "$current_version"
        
        # 期待されるバージョンと比較
        if grep -q "bundler" "$gem_file"; then
            local expected_version=$(grep "bundler" "$gem_file" | 
                                    grep -o '"~\? *[0-9][0-9.]*"' | 
                                    tr -d '"' | tr -d '~' | tr -d ' ' || 
                                    echo "")
            
            if [ -n "$expected_version" ] && [ "$current_version" != "$expected_version" ]; then
                log_warning "インストール済みのbundler ($current_version) と global-gems.rb で指定されたバージョン ($expected_version) が異なります"
                log_info "既存のbundlerを使用して続行します"
            fi
        fi
        return 0
    fi
    
    # bundlerがない場合はインストール
    log_info "global-gems.rbからbundlerの設定を確認中..."
    
    # バージョン情報の抽出
    local bundler_version=""
    if grep -q "bundler" "$gem_file"; then
        bundler_version=$(grep "bundler" "$gem_file" | 
                         grep -o '"~\? *[0-9][0-9.]*"' | 
                         tr -d '"' | tr -d '~' | tr -d ' ' || 
                         echo "")
    fi
    
    # バージョン指定有無でインストール方法を分岐
    if [ -n "$bundler_version" ]; then
        log_installing "bundler" "$bundler_version"
        if ! gem install bundler -v "$bundler_version" --no-document; then
            handle_error "bundler $bundler_version のインストールに失敗しました"
            return 1
        fi
    else
        log_installing "bundler" "標準バージョン"
        if ! gem install bundler --no-document; then
            handle_error "bundlerのインストールに失敗しました"
            return 1
        fi
    fi
    
    rbenv rehash
    log_success "bundlerのインストールが完了しました"
    return 0
}

# gemパッケージのインストール
install_gem_packages() {
    local gem_file="$1"
    
    # すでにインストール済みかチェック
    if BUNDLE_GEMFILE="$gem_file" bundle check >/dev/null 2>&1; then
        log_installed "gems"
        return 0
    fi
    
    # gemをインストール
    log_installing "gems"
    cd "$(dirname "$gem_file")" || {
        handle_error "Gemfileのディレクトリに移動できませんでした"
        return 1
    }
    
    if BUNDLE_GEMFILE="$gem_file" bundle install --quiet; then
        log_success "Gemfileからgemのインストールが完了しました"
        return 0
    elif [ "${IS_CI:-false}" = "true" ]; then
        log_warning "CI環境: gemインストールに問題がありますが続行します"
        return 0
    else
        handle_error "gemインストールに失敗しました"
        return 1
    fi
}

# Ruby環境をセットアップ
setup_ruby_env() {
    log_start "Ruby環境のセットアップを開始します..."
    
    # rbenvインストール
    install_rbenv || return 1
    
    # rbenvの初期化
    eval "$(rbenv init -)"
    
    # gemインストール（Rubyがある場合のみ実行）
    if command_exists ruby; then
        install_gems
        log_info "Ruby環境: $(ruby -v) / $(gem -v) / $(bundle -v 2>/dev/null || echo 'bundler未インストール')"
    fi
    
    log_success "Ruby環境のセットアップが完了しました"
}

# Ruby環境を検証
verify_ruby_setup() {
    log_start "Ruby環境を検証中..."
    local errors=0
    
    # rbenvチェック
    verify_rbenv_installation || ((errors++))
    
    # Rubyチェック
    verify_ruby_installation
    
    # 検証結果
    if [ $errors -eq 0 ]; then
        log_success "Ruby環境の検証が完了しました"
        return 0
    else
        log_error "Ruby環境の検証に失敗しました ($errors エラー)"
        return 1
    fi
}

# rbenvのインストールを検証
verify_rbenv_installation() {
    if ! command_exists rbenv; then
        log_error "rbenvコマンドが見つかりません"
        return 1
    fi
    
    log_success "rbenv: $(rbenv --version)"
    
    # ruby-buildの確認
    if rbenv install --version >/dev/null 2>&1 || 
       command_exists ruby-build || 
       [ -d "$(rbenv root)/plugins/ruby-build" ]; then
        log_success "ruby-buildが使用可能です"
        return 0
    else
        log_error "ruby-buildが見つかりません"
        return 1
    fi
}

# Rubyのインストールを検証
verify_ruby_installation() {
    if ! command_exists ruby; then
        log_info "Rubyはインストールされていません"
        return 0
    fi
    
    log_success "Ruby: $(ruby -v)"
    
    # gemチェック
    if ! command_exists gem; then
        log_error "gemコマンドが見つかりません"
        return 1
    fi
    
    log_success "gem: $(gem -v)"
    
    # bundlerチェック（任意）
    if command_exists bundle; then
        log_success "bundler: $(bundle -v)"
    else
        log_warning "bundlerコマンドは利用できません（global-gems.rbがない場合は正常）"
    fi
    
    return 0
}

# メイン関数
main() {
    log_start "Ruby環境のセットアップを開始します"
    
    setup_ruby_env
    
    log_success "Ruby環境のセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 