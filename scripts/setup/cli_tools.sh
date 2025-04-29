#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
source "$SCRIPT_DIR/../utils/log.sh"

BIN_DIR="$HOME/bin"

setup_cli_tools() {
    log_info "CLIツールのセットアップを開始します..."

    # シンボリックリンクを作成するターゲットディレクトリが存在するか確認
    if [ ! -d "$BIN_DIR" ]; then
        log_info "ターゲットディレクトリが存在しないため作成します: $BIN_DIR"
        mkdir -p "$BIN_DIR"
        if [ $? -ne 0 ]; then
            log_error "ディレクトリの作成に失敗しました: $BIN_DIR"
            return 1
        fi
    fi

    # --- 各CLIツールのセットアップ ---

    # 1. swstyle コマンドのシンボリックリンク作成
    log_info "'swstyle' コマンドのシンボリックリンクを作成します..."
    local SWSTYLE_SCRIPT_SOURCE="$REPO_ROOT/cli-tools/swstyle/swstyle"
    local SWSTYLE_SYMLINK_TARGET="$BIN_DIR/swstyle"

    if [ ! -f "$SWSTYLE_SCRIPT_SOURCE" ]; then
        log_error "ソーススクリプトが見つかりません: $SWSTYLE_SCRIPT_SOURCE"
    else
        ln -sf "$SWSTYLE_SCRIPT_SOURCE" "$SWSTYLE_SYMLINK_TARGET"
        if [ $? -eq 0 ]; then
            chmod +x "$SWSTYLE_SCRIPT_SOURCE" # 念のためソースにも実行権限を付与
            log_success "シンボリックリンクを作成しました: $SWSTYLE_SYMLINK_TARGET -> $SWSTYLE_SCRIPT_SOURCE"
        else
            log_error "シンボリックリンクの作成に失敗しました: $SWSTYLE_SYMLINK_TARGET -> $SWSTYLE_SCRIPT_SOURCE"
        fi
    fi

    log_info "CLIツールのセットアップが完了しました。"
    return 0
}

# スクリプトが直接実行された場合にのみ関数を呼び出す
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    setup_cli_tools
fi 