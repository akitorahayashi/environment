#!/bin/bash

# Neovimとlazy.nvimのセットアップ

# lazy.nvim のインストール
install_lazy_nvim() {
    log_start "lazy.nvimのインストールを開始します..."
    local lazy_repo="https://github.com/folke/lazy.nvim.git"
    local target_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"

    if [ ! -d "$target_path" ]; then
        log_info "lazy.nvimをクローンします: $lazy_repo -> $target_path"
        # ディレクトリが存在しない場合のみ親ディレクトリを作成
        mkdir -p "$(dirname "$target_path")"
        if git clone --filter=blob:none --single-branch "$lazy_repo" "$target_path"; then
            log_success "lazy.nvimのインストールが完了しました。"
        else
            log_error "lazy.nvimのクローンに失敗しました。"
            return 1
        fi
    else
        log_success "lazy.nvimは既にインストールされています。"
    fi
    return 0
}

# Neovim設定ファイルのセットアップ (stowを使用)
setup_nvim_config() {
    log_start "Neovim設定ファイルのセットアップを開始します..."
    local nvim_config_target_dir="$HOME/.config/nvim"
    local stow_config_dir="$REPO_ROOT/config" # stowで管理する設定ファイルの親ディレクトリ
    local stow_package="nvim"

    if [ ! -d "$stow_config_dir/$stow_package" ]; then
        log_warning "設定ディレクトリが見つかりません: $stow_config_dir/$stow_package"
        log_info "Neovim設定のセットアップをスキップします。"
        return 0
    fi

    log_info "Neovim設定ディレクトリを作成します (存在しない場合): $HOME/.config"
    mkdir -p "$HOME/.config"

    # stow実行前に、ターゲットが通常のディレクトリ/ファイルであれば削除する
    if [ -e "$nvim_config_target_dir" ] && [ ! -L "$nvim_config_target_dir" ]; then
        log_warning "既存のNeovim設定ディレクトリ (非シンボリックリンク) を削除します: $nvim_config_target_dir"
        rm -rf "$nvim_config_target_dir"
        if [ $? -ne 0 ]; then
            log_error "既存のNeovim設定ディレクトリの削除に失敗しました。"
            return 1
        fi
    fi

    log_info "'$stow_package' パッケージを '$stow_config_dir' から '$HOME/.config' にstowします..."
    if stow --dir="$stow_config_dir" --target="$HOME/.config" --restow "$stow_package"; then
        log_success "Neovim設定ファイルのシンボリックリンクを作成/更新しました。"
    else
        log_error "Neovim設定ファイルのシンボリックリンク作成/更新に失敗しました。"
        log_info "競合するファイルが存在する可能性があります。手動で確認してください。"
        return 1
    fi
    return 0
}

# メインのセットアップ関数
setup_neovim_env() {
    log_start "Neovim環境のセットアップを開始します..."
    # Neovim本体はBrewfileでインストールされる想定
    command -v nvim &> /dev/null || {
        log_error "Neovimコマンドが見つかりません。Brewfileでのインストールが成功したか確認してください。"
        return 1
    }
    install_lazy_nvim || { log_error "lazy.nvimのインストール処理でエラーが発生しました。"; return 1; }
    setup_nvim_config || { log_warning "Neovim設定ファイルのセットアップで問題が発生しました。処理は続行されます。"; } # 設定ファイルは必須ではない場合があるため警告に留める
    log_success "Neovim環境のセットアップが完了しました。"
}

# Neovim環境を検証
verify_neovim_setup() {
    log_start "Neovim環境を検証中..."
    local verification_failed=false

    # 1. nvim コマンドの存在確認
    if ! command -v nvim &> /dev/null; then
        log_error "nvim コマンドが見つかりません。Homebrewでのインストールを確認してください。"
        verification_failed=true
    else
        log_success "nvim コマンドが見つかりました: $(which nvim)"
    fi

    # 2. lazy.nvim のインストール確認
    # init.lua 及び lazy.nvim 推奨のパスに変更
    local target_path="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/lazy/lazy.nvim"
    if [ ! -d "$target_path" ]; then
        log_error "lazy.nvim がインストールされていません: $target_path"
        verification_failed=true
    else
        log_success "lazy.nvim がインストールされています: $target_path"
    fi

    # 3. Neovim 設定ファイルのシンボリックリンク確認
    local stow_config_dir="$REPO_ROOT/config"
    local stow_package="nvim"
    local nvim_config_target_dir="$HOME/.config/nvim"

    if [ -d "$stow_config_dir/$stow_package" ]; then
        # 3a. シンボリックリンク自体の確認
        if [ ! -L "$nvim_config_target_dir" ]; then
            log_error "Neovim 設定ディレクトリがシンボリックリンクではありません: $nvim_config_target_dir"
            log_info "stowによるリンクが正しく作成されているか確認してください。"
            verification_failed=true
        else
            log_success "Neovim 設定ディレクトリはシンボリックリンクです: $nvim_config_target_dir"
            # 3b. 主要な設定ファイルの存在確認 (リポジトリ内)
            local nvim_config_source_dir="$stow_config_dir/$stow_package"
            local init_lua_path="$nvim_config_source_dir/init.lua"
            local telescope_lua_path="$nvim_config_source_dir/lua/plugins/telescope.lua"

            if [ ! -f "$init_lua_path" ]; then
                log_error "Neovim 設定ファイルが見つかりません: $init_lua_path"
                verification_failed=true
            else
                log_success "Neovim 設定ファイルが見つかりました: $init_lua_path"
            fi

            if [ ! -f "$telescope_lua_path" ]; then
                log_warning "Telescope プラグイン設定ファイルが見つかりません: $telescope_lua_path"
                # verification_failed=true # オプション扱いの場合は警告のみ
            else
                log_success "Telescope プラグイン設定ファイルが見つかりました: $telescope_lua_path"
            fi
        fi
    else
        log_info "リポジトリにNeovim設定 ($stow_config_dir/$stow_package) が見つからないため、設定の検証はスキップします。"
    fi

    # 検証結果の最終判定
    if [ "$verification_failed" = "true" ]; then
        log_error "Neovim環境の検証に失敗しました"
        return 1 # 検証失敗を示す終了コード
    else
        log_success "Neovim環境の検証が正常に完了しました"
        return 0 # 検証成功を示す終了コード
    fi
}