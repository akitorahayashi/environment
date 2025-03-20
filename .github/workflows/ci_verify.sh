#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ROOT_DIR="$( cd "$SCRIPT_DIR/../.." && pwd )"

# ユーティリティのロード
source "$ROOT_DIR/scripts/utils/helpers.sh"

# セットアップスクリプトをロード
source "$ROOT_DIR/scripts/setup/flutter.sh"
source "$ROOT_DIR/scripts/setup/homebrew.sh"
source "$ROOT_DIR/scripts/setup/xcode.sh"
source "$ROOT_DIR/scripts/setup/git.sh"
source "$ROOT_DIR/scripts/setup/ruby.sh"
source "$ROOT_DIR/scripts/setup/cursor.sh"
source "$ROOT_DIR/scripts/setup/shell.sh"
source "$ROOT_DIR/scripts/setup/mac.sh"

# CI環境でBREWFILEのパスを設定
BREWFILE_PATH="$ROOT_DIR/config/Brewfile"

# 検証機能の実行
run_all_verifications() {
    log_start "🧪 環境のセットアップ検証を開始します..."
    
    local failures=0
    local total_verifications=0
    
    # Homebrewの検証
    ((total_verifications++))
    log_info "Homebrew環境の検証を開始..."
    verify_homebrew_installation || ((failures++))
    
    # Brewfileパッケージの検証
    ((total_verifications++))
    log_info "Brewfileパッケージの検証を開始..."
    verify_brewfile_packages || ((failures++))
    
    # Xcodeの検証
    ((total_verifications++))
    log_info "Xcode環境の検証を開始..."
    verify_xcode_installation || ((failures++))
    
    # Flutterの検証
    ((total_verifications++))
    log_info "Flutter環境の検証を開始..."
    verify_flutter_setup || ((failures++))
    
    # Gitの検証
    ((total_verifications++))
    log_info "Git環境の検証を開始..."
    verify_git_setup || ((failures++))
    
    # Ruby環境の検証
    ((total_verifications++))
    log_info "Ruby環境の検証を開始..."
    verify_ruby_setup || ((failures++))
    
    # Cursorの検証
    ((total_verifications++))
    log_info "Cursor環境の検証を開始..."
    verify_cursor_setup || ((failures++))
    
    # シェルの検証
    ((total_verifications++))
    log_info "シェル環境の検証を開始..."
    verify_shell_setup || ((failures++))

    # Macの検証
    ((total_verifications++))
    log_info "Mac環境の検証を開始..."
    verify_mac_setup || ((failures++))
    
    # 結果のサマリーを表示
    log_info "======================="
    log_info "検証結果サマリー: $total_verifications 項目中 $((total_verifications - failures)) 項目が成功"
    
    if [ $failures -eq 0 ]; then
        log_success "🎉 すべての検証が成功しました！"
        return 0
    else
        log_error "❌ $failures 個の検証に失敗しました"
        return 1
    fi
}

# Homebrewのインストールを検証
verify_homebrew_installation() {
    log_start "Homebrewのインストールを検証中..."
    local verification_failed=false
    
    # brewコマンドの確認
    if ! command_exists brew; then
        log_error "brewコマンドが見つかりません"
        return 1
    fi
    log_success "brewコマンドが正常に使用可能です"
    
    # バージョン確認
    if ! brew --version > /dev/null; then
        log_error "Homebrewのバージョン確認に失敗しました"
        verification_failed=true
    else
        log_success "Homebrewのバージョン: $(brew --version | head -n 1)"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Homebrewの検証に失敗しました"
        return 1
    else
        log_success "Homebrewの検証が完了しました"
        return 0
    fi
}

# Xcodeのインストールを検証
verify_xcode_installation() {
    log_start "Xcodeのインストールを検証中..."
    local verification_failed=false
    
    # Xcode Command Line Toolsの確認
    if ! xcode-select -p &>/dev/null; then
        log_error "Xcode Command Line Toolsがインストールされていません"
        verification_failed=true
    else
        log_success "Xcode Command Line Toolsがインストールされています"
    fi
    
    # Xcodeのバージョン確認
    if command_exists xcodes; then
        if ! xcodes installed | grep -q "16.2"; then
            log_error "Xcode 16.2がインストールされていません"
            verification_failed=true
        else
            log_success "Xcode 16.2がインストールされています"
        fi
    else
        log_warning "xcodesコマンドが見つかりません。Xcode 16.2のインストール状態を確認できません"
    fi
    
    # シミュレータの確認
    if xcrun simctl list runtimes &>/dev/null; then
        log_info "シミュレータの状態を確認中..."
        local missing_simulators=0
        
        for platform in iOS watchOS tvOS visionOS; do
            if ! xcrun simctl list runtimes | grep -q "$platform"; then
                log_warning "$platform シミュレータが見つかりません"
                ((missing_simulators++))
            else
                log_success "$platform シミュレータがインストールされています"
            fi
        done
        
        if [ $missing_simulators -gt 0 ]; then
            log_warning "$missing_simulators 個のシミュレータがインストールされていない可能性があります"
        fi
    else
        log_warning "simctlコマンドが使用できません。シミュレータの状態を確認できません"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Xcodeの検証に失敗しました"
        return 1
    else
        log_success "Xcodeの検証が完了しました"
        return 0
    fi
}

# Brewfileに記載されたパッケージの検証
verify_brewfile_packages() {
    log_start "Brewfileに記載されたパッケージを検証中..."
    local verification_failed=false
    local missing_packages=0
    
    # Brewfileの存在確認
    if [ ! -f "$BREWFILE_PATH" ]; then
        log_error "Brewfileが見つかりません: $BREWFILE_PATH"
        return 1
    fi
    log_success "Brewfileが存在します: $BREWFILE_PATH"
    
    # Brewfileに記載されたパッケージの総数を確認
    TOTAL_PACKAGES=$(grep -v "^#" "$BREWFILE_PATH" | grep -v "^$" | grep -c "brew\|cask" || echo "0")
    log_info "Brewfileに記載されたパッケージ数: $TOTAL_PACKAGES"
    
    # インストールされているパッケージを確認
    INSTALLED_FORMULAE=$(brew list --formula | wc -l | tr -d ' ')
    INSTALLED_CASKS=$(brew list --cask | wc -l | tr -d ' ')
    TOTAL_INSTALLED=$((INSTALLED_FORMULAE + INSTALLED_CASKS))
    
    log_info "インストールされたパッケージ数: $TOTAL_INSTALLED (formulae: $INSTALLED_FORMULAE, casks: $INSTALLED_CASKS)"
    
    # 個別パッケージの確認
    while IFS= read -r line; do
        # コメント行と空行をスキップ
        [[ $line =~ ^#.*$ ]] && continue
        [[ -z $line ]] && continue
        
        # brew または cask の行を抽出
        if [[ $line =~ ^brew\ \"([^\"]*)\" ]]; then
            package="${BASH_REMATCH[1]}"
            
            if ! brew list --formula "$package" &>/dev/null; then
                log_error "formula $package がインストールされていません"
                ((missing_packages++))
            else
                log_success "formula $package がインストールされています"
            fi
        elif [[ $line =~ ^cask\ \"([^\"]*)\" ]]; then
            package="${BASH_REMATCH[1]}"
            if ! brew list --cask "$package" &>/dev/null; then
                log_error "cask $package がインストールされていません"
                ((missing_packages++))
            else
                log_success "cask $package がインストールされています"
            fi
        fi
    done < "$BREWFILE_PATH"
    
    if [ $missing_packages -gt 0 ]; then
        log_error "$missing_packages 個のパッケージがインストールされていません"
        verification_failed=true
    else
        log_success "すべてのパッケージが正しくインストールされています"
    fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Brewfileパッケージの検証に失敗しました"
        return 1
    else
        log_success "Brewfileパッケージの検証が完了しました"
        return 0
    fi
}

# このスクリプトが直接実行された場合のみ実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # CI環境変数を設定
    export IS_CI=true
    export ALLOW_COMPONENT_FAILURE=true
    
    # すべての検証を実行
    run_all_verifications
    exit $?
fi 