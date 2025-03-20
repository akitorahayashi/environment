#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# rbenvを使ったRuby環境のセットアップ
setup_ruby_env() {
    log_start "Ruby環境のセットアップを開始します..."
    
    # rbenvがインストールされているか確認
    if ! command_exists rbenv; then
        log_info "rbenvをインストールします..."
        if ! brew install rbenv ruby-build; then
            handle_error "rbenvのインストールに失敗しました"
        fi
        log_success "rbenvのインストールが完了しました"
    else
        log_success "rbenvはすでにインストールされています"
    fi
    
    # rbenvの初期化
    log_info "rbenvを初期化します..."
    eval "$(rbenv init -)"
    
    # rbenvのセットアップの確認
    if ! rbenv versions >/dev/null 2>&1; then
        log_warning "rbenvの初期化に問題がある可能性があります"
    fi
    
    # 最新の安定版Rubyをインストール
    log_info "最新の安定版Rubyをインストールします..."
    # 最新の安定版バージョンを取得
    local latest_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -1 | tr -d ' ')
    
    # すでにインストールされているか確認
    if rbenv versions | grep -q "$latest_ruby"; then
        log_success "Ruby $latest_ruby はすでにインストールされています"
    else
        # Rubyをインストール
        log_info "Ruby $latest_ruby をインストールします..."
        if ! rbenv install "$latest_ruby"; then
            log_warning "Ruby $latest_ruby のインストールに失敗しました"
            
            # CI環境では次の安定版を試す
            if [ "$IS_CI" = "true" ]; then
                local previous_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -2 | head -1 | tr -d ' ')
                log_info "CI環境では代替バージョン $previous_ruby を試みます..."
                if ! rbenv install "$previous_ruby"; then
                    log_warning "Ruby $previous_ruby のインストールにも失敗しました"
                else
                    latest_ruby="$previous_ruby"
                    log_success "Ruby $latest_ruby のインストールが完了しました"
                fi
            fi
        else
            log_success "Ruby $latest_ruby のインストールが完了しました"
        fi
    fi
    
    # グローバルRubyバージョンを設定
    if rbenv versions | grep -q "$latest_ruby"; then
        log_info "Ruby $latest_ruby をグローバルバージョンに設定します..."
        rbenv global "$latest_ruby"
        log_success "Ruby $latest_ruby がグローバルバージョンに設定されました"
        
        # rehashしてコマンドパスを更新
        rbenv rehash
        
        # bundlerのみをインストール
        log_info "bundler gemをインストールします..."
        gem install bundler >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log_success "bundler のインストールが完了しました"
        else
            log_warning "bundler のインストールに失敗しました"
        fi
        
        # rehashして新しいgemのパスを更新
        rbenv rehash
        log_success "bundler gemのインストールが完了しました"
    else
        log_warning "Rubyがインストールされていないため、グローバルバージョンを設定できません"
    fi
    
    # 最終確認
    log_info "Ruby環境の確認:"
    ruby -v
    gem -v
    bundler -v || echo "bundlerが見つかりません"
    
    log_success "Ruby環境のセットアップが完了しました"
}

# MARK: - Verify

# Ruby環境を検証する関数
verify_ruby_setup() {
    log_start "Ruby環境を検証中..."
    local verification_failed=false
    
    # rbenvコマンドの確認
    if ! command_exists rbenv; then
        log_error "rbenvコマンドが見つかりません"
        return 1
    fi
    log_success "rbenvコマンドが使用可能です: $(rbenv --version)"
    
    # ruby-buildプラグインの確認
    RUBY_BUILD_PATH="$(rbenv root)/plugins/ruby-build"
    if [ ! -d "$RUBY_BUILD_PATH" ]; then
        log_error "ruby-buildプラグインが見つかりません"
        verification_failed=true
    else
        log_success "ruby-buildプラグインが存在します"
    fi
    
    # rbenv初期化の確認
    if ! rbenv versions >/dev/null 2>&1; then
        log_error "rbenvの初期化に問題があります"
        verification_failed=true
    else
        log_success "rbenvが正しく初期化されています"
    fi
    
    # Ruby（システムまたはrbenv）確認
    if ! command_exists ruby; then
        log_error "rubyコマンドが見つかりません"
        verification_failed=true
    else
        RUBY_VERSION=$(ruby -v)
        log_success "Rubyが使用可能です: $RUBY_VERSION"
    fi
    
    # Bundlerの確認
    if ! command_exists bundle; then
        log_warning "bundlerコマンドが見つかりません"
    else
        BUNDLER_VERSION=$(bundle -v)
        log_success "Bundlerが使用可能です: $BUNDLER_VERSION"
    fi
    
    # gemコマンドの確認
    if ! command_exists gem; then
        log_error "gemコマンドが見つかりません"
        verification_failed=true
    else
        log_success "gemコマンドが使用可能です: $(gem -v)"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Ruby環境の検証に失敗しました"
        return 1
    else
        log_success "Ruby環境の検証が完了しました"
        return 0
    fi
} 