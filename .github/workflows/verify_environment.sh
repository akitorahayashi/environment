#!/bin/bash
# macOS環境の検証スクリプト
# 用途：インストール後の環境が正しく構成されているかを検証する

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# 必要なユーティリティを読み込み
source "$REPO_ROOT/scripts/utils/helpers.sh"
source "$REPO_ROOT/scripts/utils/logging.sh"

# 検証対象のコンポーネントを読み込み
source "$REPO_ROOT/scripts/setup/homebrew.sh"
source "$REPO_ROOT/scripts/setup/xcode.sh"
source "$REPO_ROOT/scripts/setup/flutter.sh"
source "$REPO_ROOT/scripts/setup/git.sh"
source "$REPO_ROOT/scripts/setup/shell.sh"
source "$REPO_ROOT/scripts/setup/mac.sh"
source "$REPO_ROOT/scripts/setup/reactnative.sh"

# CI環境フラグを設定
export IS_CI=true
export ALLOW_COMPONENT_FAILURE=true

# 検証項目の定義
VERIFICATION_COMPONENTS=(
  "シェル環境,verify_shell_setup"
  "Mac環境,verify_mac_setup"
  "Homebrew,verify_homebrew_setup"
  "Xcode,verify_xcode_installation"
  "Git環境,verify_git_setup"
  "Flutter環境,verify_flutter_setup"
  "React Native環境,verify_reactnative_setup"
)

# 検証を実行
run_verifications() {
  local failure_count=0
  local success_count=0
  local total_count=${#VERIFICATION_COMPONENTS[@]}
  
  log_info "🧪 macOS環境の検証を開始します..."
  
  # 検証を項目ごとに実行
  for item in "${VERIFICATION_COMPONENTS[@]}"; do
    IFS=',' read -r name func <<< "$item"
    
    log_info "${name}の検証を開始..."
    
    # 検証関数を実行
    if $func; then
      log_success "${name}の検証に成功しました"
      ((success_count++))
    else
      log_error "${name}の検証に失敗しました"
      ((failure_count++))
    fi
  done
  
  # 結果の表示
  log_info "======================"
  log_info "検証結果: ${total_count}項目中 ${success_count}項目が成功"
  
  if [ $failure_count -eq 0 ]; then
    log_success "🎉 すべての検証に成功しました！"
    return 0
  else
    log_error "❌ ${failure_count}個の検証項目に失敗しました"
    return 1
  fi
}

# 検証を実行
run_verifications
exit $? 