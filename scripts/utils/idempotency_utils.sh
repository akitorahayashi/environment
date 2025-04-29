#!/bin/bash

# このスクリプトが配置されているディレクトリを取得 (scripts/utils/)
IDEMPOTENCY_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# リポジトリルートを想定 (.github/scripts/ から2つ上)
# REPO_ROOT は install.sh など呼び出し元から export されている想定だが、なければ計算
REPO_ROOT="${REPO_ROOT:-$(cd "$IDEMPOTENCY_SCRIPT_DIR/../../" &>/dev/null && pwd)}"

# ユーティリティのロード (logging.sh - 同じディレクトリにあるはず)
source "$IDEMPOTENCY_SCRIPT_DIR/logging.sh" || {
    echo "[Idempotency Utils] Error: Failed to load logging.sh" >&2
    exit 1
}

# 冪等性テスト用の変数
declare IDEMPOTENT_TEST="${IDEMPOTENT_TEST:-false}"
declare IDEMPOTENT_VIOLATIONS=()

# コンポーネントが2回目以降で再インストールされようとしているかチェック
check_idempotence() {
    local component="$1"
    local message="$2"

    if [ "${IDEMPOTENT_TEST}" = "true" ]; then
        log_warning "🔍 冪等性違反: ${component} が2回目の実行でインストールを試みています"
        log_warning "🔍 詳細: ${message}"
        IDEMPOTENT_VIOLATIONS+=("${component}: ${message}")
    fi
}

# 冪等性違反をレポート
report_idempotence_violations() {
    if [ "${#IDEMPOTENT_VIOLATIONS[@]}" -gt 0 ]; then
        log_error "==== 冪等性テスト結果: 失敗 ===="
        log_error "以下のコンポーネントが2回目の実行でもインストールを試みています:"
        for violation in "${IDEMPOTENT_VIOLATIONS[@]}"; do
            log_error "- ${violation}"
        done
        return 1
    else
        log_success "==== 冪等性テスト結果: 成功 ===="
        log_success "すべてのコンポーネントが正しく冪等性を維持しています"
        return 0
    fi
}

# 2回目実行を検出するフラグを設定
mark_second_run() {
    export IDEMPOTENT_TEST="true"
    log_info "🔍 冪等性テストモードが有効になりました"
} 