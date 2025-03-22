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
        log_info "rbenvをインストール中..."
        if ! brew install rbenv ruby-build; then
            handle_error "rbenvのインストールに失敗しました"
        fi
        log_success "rbenvのインストールが完了しました"
    else
        log_success "rbenvはすでにインストールされています"
    fi
    
    # rbenvの初期化
    log_info "rbenvを初期化中..."
    eval "$(rbenv init -)"
    
    # rbenvのセットアップの確認
    if ! rbenv versions >/dev/null 2>&1; then
        log_warning "rbenvの初期化に問題がある可能性があります"
    fi
    
    # 最新の安定版Rubyをインストール
    log_info "最新の安定版Rubyをインストール中..."
    # 最新の安定版バージョンを取得
    local latest_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -1 | tr -d ' ')
    
    # すでにインストールされているか確認
    if rbenv versions | grep -q "$latest_ruby"; then
        log_success "Ruby $latest_ruby はすでにインストールされています"
    else
        # Rubyをインストール
        log_info "Ruby $latest_ruby をインストール中..."
        if ! rbenv install "$latest_ruby"; then
            log_warning "Ruby $latest_ruby のインストールに失敗しました"
            
            # CI環境では次の安定版を試す
            if [ "$IS_CI" = "true" ]; then
                local previous_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -2 | head -1 | tr -d ' ')
                log_info "CI環境では代替バージョン $previous_ruby を試み中..."
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
        log_info "Ruby $latest_ruby をグローバルバージョンに設定中..."
        rbenv global "$latest_ruby"
        log_success "Ruby $latest_ruby がグローバルバージョンに設定されました"
        
        # rehashしてコマンドパスを更新
        rbenv rehash
        
        # Gemfileからグローバルgemをインストール
        global_gemfile="$ROOT_DIR/config/global-gems.rb"
        if [ -f "$global_gemfile" ]; then
            log_info "Gemfileを使用してグローバルgemをインストール中..."
            
            # bundlerを最初にインストール（Gemfileを使うために必要）
            if ! command_exists bundle; then
                log_info "bundler gemをインストール中..."
                gem install bundler >/dev/null 2>&1
                if [ $? -ne 0 ]; then
                    log_warning "bundler のインストールに失敗しました"
                fi
                rbenv rehash
            fi
            
            # Gemfileからインストール
            log_info "Gemfileからgemをインストール中..."
            BUNDLE_GEMFILE="$global_gemfile" bundle install
            if [ $? -eq 0 ]; then
                log_success "Gemfileからのgemインストールが完了しました"
            else
                log_warning "Gemfileからのgemインストールに問題がありました"
            fi
        else
            # Gemfileがない場合は基本的なbundlerのみをインストール
            log_info "global-gems.rbが見つからないため、bundler gemのみをインストール中..."
            gem install bundler >/dev/null 2>&1
            if [ $? -eq 0 ]; then
                log_success "bundler のインストールが完了しました"
            else
                log_warning "bundler のインストールに失敗しました"
            fi
        fi
        
        # rehashして新しいgemのパスを更新
        rbenv rehash
        log_success "Ruby gemのインストールが完了しました"
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
    
    # ruby-buildの確認（複数の可能な形態に対応）
    ruby_build_found=false

    # 方法1: 直接コマンドとして存在するか確認
    if command_exists ruby-build; then
        log_success "ruby-buildコマンドが使用可能です"
        ruby_build_found=true
    # 方法2: rbenv installコマンドが使用可能か確認
    elif rbenv install --version > /dev/null 2>&1; then
        log_success "rbenv installコマンドが使用可能です（ruby-buildが正しく機能しています）"
        ruby_build_found=true
    # 方法3: rbenvプラグインディレクトリにruby-buildがあるか確認
    elif [ -d "$(rbenv root)/plugins/ruby-build" ]; then
        log_success "ruby-buildプラグインが存在します: $(rbenv root)/plugins/ruby-build"
        ruby_build_found=true
    # 方法4: Homebrewのリンクされたディレクトリにruby-buildがあるか確認
    elif [ -f "/opt/homebrew/Cellar/ruby-build/"*"/bin/ruby-build" ]; then
        log_success "ruby-buildがHomebrewからインストールされています"
        ruby_build_found=true
    fi

    # 結果判定
    if [ "$ruby_build_found" = "false" ]; then
        if [ "$IS_CI" = "true" ] && command_exists ruby; then
            log_info "CI環境: ruby-buildが見つかりませんが、rubyコマンドは使用可能です"
        else
            log_error "ruby-buildが見つかりません"
            verification_failed=true
        fi
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

# rbenv のインストール
install_rbenv() {
    # すでにインストールされているか確認
    if command_exists rbenv; then
        log_success "rbenv はすでにインストールされています ✓"
        return 0
    fi
    
    log_info "rbenvをインストール中..."
    brew install rbenv ruby-build || {
        handle_error "rbenvのインストールに失敗しました"
    }
    
    # シェル初期化
    if rbenv init - > /dev/null 2>&1; then
        log_success "rbenv が正常にインストールされました ✓"
        eval "$(rbenv init -)"
    else
        handle_error "rbenvの初期化に失敗しました"
    fi
}

# 最新の安定版Rubyをインストール
install_latest_ruby() {
    log_info "最新の安定版Rubyをインストール中..."
    
    # 最新の安定版を取得
    latest_ruby=$(rbenv install -l | grep -v - | grep -v dev | tail -1 | tr -d ' ')
    
    if [ -z "$latest_ruby" ]; then
        handle_error "最新のRubyバージョンを取得できませんでした"
    fi
    
    # Rubyをインストール
    log_info "Ruby $latest_ruby をインストール中..."
    rbenv install -s "$latest_ruby" || {
        handle_error "Ruby ${latest_ruby}のインストールに失敗しました"
    }
    
    # グローバルRubyを設定
    rbenv global "$latest_ruby"
    
    # 確認
    installed_ruby=$(rbenv global)
    if [ "$installed_ruby" = "$latest_ruby" ]; then
        log_success "Ruby $latest_ruby がインストールされ、グローバルに設定されました ✓"
    else
        handle_error "Rubyのグローバル設定に失敗しました"
    fi
    
    # rehash
    rbenv rehash
}

# Gemfileからグローバルgemをインストール
install_global_gems() {
    local gem_file="${REPO_ROOT}/config/global-gems.rb"
    
    log_info "Gemfileを使用してグローバルgemをインストール中..."
    
    # bundlerをインストール
    log_info "bundler gemをインストール中..."
    if ! gem list bundler -i > /dev/null 2>&1; then
        gem install bundler || {
            handle_error "bundlerのインストールに失敗しました"
        }
        log_success "bundlerがインストールされました ✓"
    else
        log_success "bundlerはすでにインストールされています ✓"
    fi
    
    if [ -f "$gem_file" ]; then
        log_info "Gemfileからgemをインストール中..."
        cd "$(dirname "$gem_file")" || {
            handle_error "Gemfileのディレクトリに移動できませんでした"
        }
        bundle install || {
            handle_error "Gemfileからのgemインストールに失敗しました"
        }
        log_success "Gemfileからgemがインストールされました ✓"
    else
        # Gemfileがない場合は基本的なbundlerのみをインストール
        log_info "global-gems.rbが見つからないため、bundler gemのみをインストール中..."
    fi
} 