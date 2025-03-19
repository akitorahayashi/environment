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