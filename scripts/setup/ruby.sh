#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# rbenvをインストール
install_rbenv() {
    if command_exists rbenv; then
        log_success "rbenvは既にインストール済みです"
        return 0
    fi
    
    log_info "rbenvをインストール中..."
    if brew install rbenv ruby-build; then
        log_success "rbenvのインストールが完了しました"
        eval "$(rbenv init -)"
        return 0
    else
        handle_error "rbenvのインストールに失敗しました"
        return 1
    fi
}

# 最新のRubyをインストール
install_ruby() {
    # 最新の安定版バージョンを取得
    local latest_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -1 | tr -d ' ')
    
    if rbenv versions | grep -q "$latest_ruby"; then
        log_success "Ruby $latest_ruby は既にインストール済みです"
    else
        log_info "Ruby $latest_ruby をインストール中..."
        if ! rbenv install -s "$latest_ruby"; then
            if [ "${IS_CI:-false}" = "true" ]; then
                log_warning "CI環境: Ruby $latest_ruby のインストールに失敗しました、代替を試みます"
                local previous_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -2 | head -1 | tr -d ' ')
                if rbenv install -s "$previous_ruby"; then
                    latest_ruby="$previous_ruby"
                    log_success "Ruby $latest_ruby のインストールが完了しました"
                else
                    handle_error "RubyのCI代替インストールにも失敗しました"
                    return 1
                fi
            else
                handle_error "Ruby $latest_ruby のインストールに失敗しました"
                return 1
            fi
        else
            log_success "Ruby $latest_ruby のインストールが完了しました"
        fi
        
        # 新しくインストールされた場合のみグローバルRubyバージョンを設定
        log_info "Ruby $latest_ruby をグローバルバージョンに設定中..."
        rbenv global "$latest_ruby"
        rbenv rehash
        log_success "Ruby $latest_ruby がグローバルバージョンに設定されました"
    fi
    
    return 0
}

# Gemfileからgemをインストール
install_gems() {
    local gem_file="${REPO_ROOT:-$ROOT_DIR}/config/global-gems.rb"
    
    if [ ! -f "$gem_file" ]; then
        log_info "global-gems.rbが見つかりません。gemのインストールをスキップします"
        return 0
    fi
    
    log_info "Gemfileからgemをインストール中..."
    
    # bundlerチェック
    if ! command_exists bundle; then
        log_info "bundlerをインストール中（Gemfile使用のため）..."
        if ! gem install bundler --no-document; then
            handle_error "bundlerのインストールに失敗しました"
            return 1
        fi
        rbenv rehash
    fi
    
    # すでにインストール済みかチェック
    if BUNDLE_GEMFILE="$gem_file" bundle check >/dev/null 2>&1; then
        log_success "すべてのgemは既にインストール済みです"
        return 0
    fi
    
    # gemをインストール
    cd "$(dirname "$gem_file")" || {
        handle_error "Gemfileのディレクトリに移動できませんでした"
        return 1
    }
    
    if BUNDLE_GEMFILE="$gem_file" bundle install --quiet; then
        log_success "Gemfileからgemのインストールが完了しました"
        return 0
    else
        if [ "${IS_CI:-false}" = "true" ]; then
            log_warning "CI環境: gemインストールに問題がありますが続行します"
            return 0
        else
            handle_error "gemインストールに失敗しました"
            return 1
        fi
    fi
}

# Ruby環境をセットアップする
setup_ruby_env() {
    log_start "Ruby環境のセットアップを開始します..."
    
    # 1. rbenvインストール
    install_rbenv || return 1
    
    # rbenvの初期化
    eval "$(rbenv init -)"
    
    # 2. Rubyインストール
    install_ruby || return 1
    
    # 3. gemインストール
    install_gems
    
    # 4. 最終確認
    log_info "Ruby環境: $(ruby -v) / $(gem -v) / $(bundle -v 2>/dev/null || echo 'bundler未インストール')"
    log_success "Ruby環境のセットアップが完了しました"
}

# Ruby環境を検証
verify_ruby_setup() {
    log_start "Ruby環境を検証中..."
    local errors=0
    
    # rbenvチェック
    if ! command_exists rbenv; then
        log_error "rbenvコマンドが見つかりません"
        ((errors++))
    else
        log_success "rbenv: $(rbenv --version)"
        
        # ruby-buildの確認
        if rbenv install --version >/dev/null 2>&1 || command_exists ruby-build || [ -d "$(rbenv root)/plugins/ruby-build" ]; then
            log_success "ruby-buildが使用可能です"
        else
            log_error "ruby-buildが見つかりません"
            ((errors++))
        fi
    fi
    
    # Rubyチェック
    if ! command_exists ruby; then
        log_error "rubyコマンドが見つかりません"
        ((errors++))
    else
        log_success "Ruby: $(ruby -v)"
    fi
    
    # gemチェック
    if ! command_exists gem; then
        log_error "gemコマンドが見つかりません"
        ((errors++))
    else
        log_success "gem: $(gem -v)"
    fi
    
    # bundlerは任意
    if command_exists bundle; then
        log_success "bundler: $(bundle -v)"
    else
        log_warning "bundlerコマンドは利用できません（global-gems.rbがない場合は正常）"
    fi
    
    if [ $errors -eq 0 ]; then
        log_success "Ruby環境の検証が完了しました"
        return 0
    else
        log_error "Ruby環境の検証に失敗しました ($errors エラー)"
        return 1
    fi
} 