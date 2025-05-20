#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../../" && pwd )"

# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"
source "$SCRIPT_DIR/../utils/logging.sh"

# Xcode とシミュレータのインストール
install_xcode() {
    log_start "Xcode のインストールを開始します..."
    local xcode_install_success=true
    
    # 各コンポーネントをインストール
    install_xcode_command_line_tools || xcode_install_success=false
    install_xcodes_cli || xcode_install_success=false
    install_xcode_app || xcode_install_success=false
    
    # シミュレータのインストールは削除
    # if [ "$xcode_install_success" = true ]; then
    #     install_xcode_simulators || xcode_install_success=false # Remove call
    # else
    #     log_error "Xcode のインストールに失敗したため、シミュレータのインストールをスキップします"
    #     return 1
    # fi
    
    if [ "$xcode_install_success" = true ]; then
        log_success "Xcode のインストールが完了しました！" # メッセージからシミュレータを削除
        return 0
    else
        log_error "Xcode のインストールに失敗しました" # メッセージからシミュレータを削除
        return 1
    fi
}

# Xcode Command Line Toolsのインストール
install_xcode_command_line_tools() {
    # Xcode Command Line Tools のインストール
    if ! xcode-select -p &>/dev/null; then
        log_installing "Xcode Command Line Tools"
        if [ "$IS_CI" = "true" ]; then
            # CI環境ではすでにインストールされていることを前提とする
            log_info "CI環境では Xcode Command Line Tools はすでにインストールされていると想定します"
        else
            xcode-select --install
            # インストールが完了するまで待機
            log_info "インストールが完了するまで待機..."
            until xcode-select -p &>/dev/null; do
                sleep 5
            done
        fi
        log_success "Xcode Command Line Tools のインストール完了"
    else
        log_installed "Xcode Command Line Tools"
    fi
    
    return 0
}

# xcodes CLIのインストール
install_xcodes_cli() {
    if ! command_exists xcodes; then
        log_installing "xcodes"
        if brew install xcodes; then
            log_success "xcodes のインストールが完了しました"
            return 0
        else
            log_error "xcodes のインストールに失敗しました"
            return 1
        fi
    else
        log_installed "xcodes"
        return 0
    fi
}

# Xcodeアプリのインストール
install_xcode_app() {
    # Xcode 16.2 がインストールされているか確認
    if ! command_exists xcodes; then
        log_error "xcodes が使用できないため、Xcode 16.2 をインストールできません"
        return 1
    fi
    
    if ! xcodes installed | grep -q "16.2"; then
        log_installing "Xcode" "16.2"
        if ! xcodes install 16.2 --select; then
            log_error "Xcode 16.2 のインストールに失敗しました"
            return 1
        fi
    else
        log_installed "Xcode" "16.2"
        setup_xcode_path
    fi
    
    return 0
}

# Xcodeパスの設定
setup_xcode_path() {
    log_info "Xcodeのパス設定を確認中..."
    local current_xcode_path=$(xcode-select -p)
    local expected_xcode_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1)
    
    # 現在のパスがXcodeのDeveloperディレクトリを指しているかチェック
    if [[ -n "$current_xcode_path" && 
          "$current_xcode_path" == *"/Contents/Developer" && 
          ! "$current_xcode_path" == *"CommandLineTools"* ]]; then
        log_success "Xcodeのパスは正しく設定されています: $current_xcode_path"
        return 0
    fi
    
    # Xcodeが見つかった場合、パスを設定
    if [ -n "$expected_xcode_path" ]; then
        log_info "Xcodeが見つかりました: $expected_xcode_path"
        return set_xcode_path "$expected_xcode_path/Contents/Developer"
    else
        log_warning "Xcodeのパスが見つかりません。ただし続行します"
        return 0
    fi
}

# Xcodeパスの設定処理
set_xcode_path() {
    local xcode_path="$1"
    
    log_info "Xcodeのパスを設定中..."
    if xcode-select --switch "$xcode_path" 2>/dev/null; then
        log_success "Xcodeのパスの設定が完了しました"
        return 0
    fi
    
    # sudo権限が必要な場合
    prompt_for_sudo "Xcodeのパスを設定する"
    if sudo xcode-select --switch "$xcode_path" 2>/dev/null; then
        log_success "Xcodeのパスの設定が完了しました"
        return 0
    else
        log_warning "Xcodeのパス設定に失敗しましたが、続行します"
        log_info "必要に応じて次のコマンドを手動で実行してください: sudo xcode-select --switch \"$xcode_path\""
        return 1
    fi
}

# MARK: - Verify

# Xcodeのインストールを検証する関数
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
    
    # シミュレータの確認は削除
    # if xcrun simctl list runtimes &>/dev/null; then
    #    ...
    # fi
    
    if [ "$verification_failed" = "true" ]; then
        log_error "Xcodeの検証に失敗しました"
        return 1
    else
        log_success "Xcodeの検証が完了しました"
        return 0
    fi
}

# Xcodeシミュレータのインストールを検証する関数 (削除)
# verify_xcode_simulators() {
#     ...
# }

# メイン関数
main() {
    log_start "Xcodeのセットアップを開始します"
    
    if ! install_xcode; then
        handle_error "Xcodeのインストールに問題がありました"
    else
        log_success "Xcodeのインストールが完了しました"
    fi
    
    log_success "Xcodeのセットアップが完了しました"
}

# スクリプトが直接実行された場合のみメイン関数を実行
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 