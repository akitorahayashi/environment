#!/bin/bash

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# ユーティリティのロード
source "$SCRIPT_DIR/../utils/helpers.sh"

# Xcode とシミュレータのインストール
install_xcode() {
    log_start "Xcode のインストールを開始します..."
    local xcode_install_success=true

    # Xcode Command Line Tools のインストール
    if ! xcode-select -p &>/dev/null; then
        log_start "Xcode Command Line Tools をインストール中..."
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
        log_success "Xcode Command Line Tools はすでにインストール済み"
    fi

    # xcodes がインストールされているか確認
    if ! command_exists xcodes; then
        log_error "xcodes がインストールされていません。インストール中..."
        if brew install xcodes; then
            log_success "xcodes のインストールが完了しました"
        else
            log_error "xcodes のインストールに失敗しました"
            xcode_install_success=false
            return 1
        fi
    fi

    # Xcode 16.2 がインストールされているか確認
    if command_exists xcodes; then
        if ! xcodes installed | grep -q "16.2"; then
            log_start "Xcode 16.2 をインストール中..."
            if ! xcodes install 16.2 --select; then
                log_error "Xcode 16.2 のインストールに失敗しました"
                xcode_install_success=false
                return 1
            fi
        else
            log_success "Xcode 16.2 はすでにインストールされています"
            
            # Xcodeがインストールされている場合、パス設定が必要か確認
            log_info "Xcodeのパス設定を確認中..."
            local current_xcode_path=$(xcode-select -p)
            local expected_xcode_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1)
            
            # 現在のパスがXcodeのDeveloperディレクトリを指しているかチェック
            if [[ -n "$current_xcode_path" && "$current_xcode_path" == *"/Contents/Developer" && ! "$current_xcode_path" == *"CommandLineTools"* ]]; then
                log_success "Xcodeのパスは正しく設定されています: $current_xcode_path"
            elif [ -n "$expected_xcode_path" ]; then
                log_info "Xcodeが見つかりました: $expected_xcode_path"
                # Xcodeのパスを設定
                log_info "Xcodeのパスを設定中..."
                if xcode-select --switch "$expected_xcode_path/Contents/Developer" 2>/dev/null; then
                    log_success "Xcodeのパスの設定が完了しました"
                else
                    # sudo権限が必要な場合のみプロンプト表示
                    prompt_for_sudo "Xcodeのパスを設定する"
                    if sudo xcode-select --switch "$expected_xcode_path/Contents/Developer" 2>/dev/null; then
                        log_success "Xcodeのパスの設定が完了しました"
                    else
                        log_warning "Xcodeのパス設定に失敗しましたが、続行します"
                        log_info "必要に応じて次のコマンドを手動で実行してください: sudo xcode-select --switch \"$expected_xcode_path/Contents/Developer\""
                    fi
                fi
            else
                log_warning "Xcodeのパスが見つかりません。ただし続行します"
            fi
        fi
    else
        xcode_install_success=false
        log_error "xcodes が使用できないため、Xcode 16.2 をインストールできません"
        return 1
    fi

    # シミュレータのインストール
    if [ "$xcode_install_success" = true ]; then
        log_start "シミュレータの確認中..."
        local need_install=false
        local platforms=("iOS" "watchOS" "tvOS" "visionOS")
        
        # シミュレータのチェック方法を改善
        for platform in "${platforms[@]}"; do
            # シミュレータの検証を複数の方法で実施
            local simulator_found=false
            
            # 方法1: xcrun simctl list runtime でチェック
            if xcrun simctl list runtimes 2>/dev/null | grep -q "$platform"; then
                simulator_found=true
                log_success "$platform シミュレータが見つかりました (simctl)"
            # 方法2: Runtimesディレクトリをチェックするがファイルの中身も確認
            elif [ -d "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" ] && ls -la "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" 2>/dev/null | grep -q "$platform"; then
                # ディレクトリが存在し、かつ中身も確認
                if [ -n "$(find "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" -name "*$platform*" -type d 2>/dev/null)" ]; then
                    simulator_found=true
                    log_success "$platform シミュレータが見つかりました (ファイルシステム)"
                fi
            fi
            
            # 方法3: デバイスリストに存在するか確認
            if ! $simulator_found && xcrun simctl list devices 2>/dev/null | grep -q "$platform"; then
                simulator_found=true
                log_success "$platform 用のデバイスが存在します"
            fi
            
            # シミュレータが見つからない場合は再インストールが必要
            if ! $simulator_found; then
                need_install=true
                log_info "❓ $platform シミュレータが見つかりません。インストールが必要です。"
            fi
        done

        # シミュレータのインストールが必要な場合
        if [ "$need_install" = true ]; then
            log_start "必要なシミュレータをインストール中..."
            
            # Xcodeが正しく設定されているか確認
            local xcode_selected_path=$(xcode-select -p)
            if [[ "$xcode_selected_path" == *"CommandLineTools"* ]]; then
                log_warning "Xcodeが正しく設定されていません。現在のパス: $xcode_selected_path"
                
                # Xcodeを自動検出して設定
                local xcode_app_path=$(mdfind "kMDItemCFBundleIdentifier == 'com.apple.dt.Xcode'" | head -n 1)
                if [ -n "$xcode_app_path" ]; then
                    prompt_for_sudo "シミュレータのインストールのためXcodeのパスを設定"
                    if sudo xcode-select --switch "$xcode_app_path/Contents/Developer" 2>/dev/null; then
                        log_success "Xcodeのパスの設定が完了しました: $xcode_app_path/Contents/Developer"
                    else
                        log_warning "sudo権限がないため、シミュレータのインストールをスキップします"
                        log_info "次のコマンドを手動で実行してください: sudo xcode-select --switch \"$xcode_app_path/Contents/Developer\""
                        log_info "その後、Xcodeを起動し、Preferences -> Components からシミュレータをインストールしてください"
                        return 0  # エラーとして扱わず続行
                    fi
                else
                    log_warning "Xcodeが見つかりません。シミュレータのインストールをスキップします"
                    return 0  # エラーとして扱わず続行
                fi
            fi
            
            # シミュレータのインストール
            for platform in "${platforms[@]}"; do
                # シミュレータの検証を複数の方法で実施
                local simulator_found=false
                
                # 同じチェックを再度実行
                if xcrun simctl list runtimes 2>/dev/null | grep -q "$platform" || \
                   ([ -d "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" ] && \
                   [ -n "$(find "$HOME/Library/Developer/CoreSimulator/Profiles/Runtimes" -name "*$platform*" -type d 2>/dev/null)" ]); then
                    simulator_found=true
                fi
                
                # シミュレータが見つからない場合はインストールを試みる
                if ! $simulator_found; then
                    log_info "➕ $platform シミュレータをインストール中..."
                    if ! xcodebuild -downloadPlatform "$platform"; then
                        log_warning "$platform シミュレータのインストールに失敗しました"
                        log_info "Xcodeを起動し、Settings -> Platforms から手動でインストールしてください"
                    else
                        log_success "$platform シミュレータのインストールが完了しました"
                    fi
                fi
            done
            
            # インストール後の最終チェック
            log_info "シミュレータの状態を確認中..."
            xcrun simctl list runtimes 2>/dev/null | grep -E 'iOS|watchOS|tvOS|visionOS' || echo "利用可能なランタイムがありません"
        else
            log_success "すべての必要なシミュレータは既にインストールされています"
        fi
    else
        log_error "Xcode のインストールに失敗したため、シミュレータのインストールをスキップします"
        return 1
    fi

    # Xcode インストール後に SwiftLint をインストール
    if [ "$xcode_install_success" = true ] && ! command_exists swiftlint; then
        log_start "SwiftLint をインストール中..."
        if brew install swiftlint; then
            log_success "SwiftLint のインストールが完了しました"
        else
            log_error "SwiftLint のインストールに失敗しました"
            return 1
        fi
    elif command_exists swiftlint; then
        log_success "SwiftLint はすでにインストールされています"
    fi

    if [ "$xcode_install_success" = true ]; then
        log_success "Xcode とシミュレータのインストールが完了しました！"
        return 0
    else
        log_error "Xcode またはシミュレータのインストールに失敗しました"
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

# Xcodeシミュレータのインストールを検証する関数
verify_xcode_simulators() {
    log_info "Xcodeシミュレータを検証中..."
    local simulators_missing=false
    local missing_simulators=0
    
    # simctlコマンドの確認
    if ! xcrun simctl list runtimes &>/dev/null; then
        log_error "simctlコマンドが正常に動作していません"
        return 1
    fi
    
    # 各プラットフォームのシミュレータを確認
    for platform in iOS watchOS tvOS visionOS; do
        if ! xcrun simctl list runtimes | grep -q "$platform"; then
            log_warning "$platform シミュレータが見つかりません"
            ((missing_simulators++))
            simulators_missing=true
        else
            log_success "$platform シミュレータがインストールされています"
            
            # そのプラットフォームの最新バージョンを取得してデバイスを確認
            LATEST_RUNTIME=$(xcrun simctl list runtimes | grep "$platform" | tail -n 1 | awk '{print $2}')
            if [ -n "$LATEST_RUNTIME" ]; then
                DEVICE_COUNT=$(xcrun simctl list devices | grep -A 100 "$LATEST_RUNTIME" | grep -m 1 -B 100 "==" | grep -v "==" | grep -v "^--" | grep -c "([0-9A-F-]\+) (")
                log_info "$platform の利用可能なデバイス数: $DEVICE_COUNT"
            fi
        fi
    done
    
    if [ "$simulators_missing" = "true" ]; then
        log_warning "$missing_simulators 個のプラットフォームシミュレータがインストールされていません"
        return 1
    else
        log_success "すべてのプラットフォームシミュレータがインストールされています"
        return 0
    fi
} 