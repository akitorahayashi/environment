#!/bin/bash
# macOS環境セットアップのテスト実行スクリプト
# 用途：インストールプロセスの実行と冪等性テスト

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

# 基本環境変数を設定
setup_ci_environment() {
  export JAVA_HOME=$(dirname $(dirname $(readlink -f $(which java))))
  export ANDROID_SDK_ROOT=$HOME/Library/Android/sdk
  export REPO_ROOT=${GITHUB_WORKSPACE:-$REPO_ROOT}
  export IS_CI=true
  export ALLOW_COMPONENT_FAILURE=true
}

# スクリプトに実行権限を付与
chmod +x "$REPO_ROOT/install.sh"
chmod +x "$REPO_ROOT/scripts/setup/"*.sh
chmod +x "$REPO_ROOT/scripts/utils/"*.sh
chmod +x "$REPO_ROOT/.github/workflows/"*.sh
chmod +x "$REPO_ROOT/.github/scripts/"*.sh

# コマンドライン引数を処理
ACTION=${1:-all}

case "$ACTION" in
  "first") # 初回インストールのみ実行
    # CIモードで初回インストール実行
    setup_ci_environment
    echo "🚀 インストールを実行しています..."
    
    "$REPO_ROOT/install.sh" | tee install_output.log
    
    # インストールメッセージが含まれているか確認
    if grep -q -E "(をインストール中|📦|環境のセットアップ)" install_output.log; then
      echo "✅ インストールメッセージを確認しました"
    else
      echo "❌ インストールメッセージが見つかりませんでした"
      echo "=== インストール出力サンプル ==="
      head -n 20 install_output.log
      exit 1
    fi
    ;;
    
  "idempotent") # 冪等性テストのみ実行
    # 冪等性テストモードでインストール実行
    setup_ci_environment
    export IDEMPOTENT_TEST=true
    
    echo "🔍 冪等性テストを実行しています..."
    "$REPO_ROOT/install.sh" | tee idempotent_output.log
    
    # インストールメッセージがないことを確認（冪等性）
    if grep -q "インストール中" idempotent_output.log; then
      echo "❌ 冪等性テスト失敗：2回目の実行でインストールメッセージが見つかりました"
      grep -A 3 -B 3 "インストール中" idempotent_output.log
      exit 1
    fi
    
    # スキップメッセージがあることを確認
    if grep -q -E "(すでにインストール済み|スキップ)" idempotent_output.log; then
      echo "✅ 冪等性テスト成功：適切なスキップメッセージが確認できました"
    else
      echo "⚠️ 警告：スキップメッセージが見つかりませんでした"
    fi
    ;;
    
  "verify") # 環境検証のみ実行
    setup_ci_environment
    echo "🔍 環境検証を実行中..."
    
    "$REPO_ROOT/.github/scripts/verify_environment.sh"
    exit $?
    ;;
    
  "all") # すべてのテストを順に実行
    echo "===== 1. 初回インストールテスト ====="
    "$0" first || exit $?
    
    echo "===== 2. 冪等性テスト ====="
    "$0" idempotent || exit $?
    
    echo "===== 3. 環境検証 ====="
    "$0" verify || exit $?
    
    echo "🎉 すべてのテストが正常に完了しました！"
    ;;
    
  *)
    echo "使用法: $0 [first|idempotent|verify|all]"
    echo "  first      - 初回インストールのみ実行"
    echo "  idempotent - 冪等性テストのみ実行"
    echo "  verify     - 環境検証のみ実行"
    echo "  all        - すべてのテストを実行（デフォルト）"
    exit 1
    ;;
esac

exit 0 