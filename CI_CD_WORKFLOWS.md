# CI/CD Workflows

このディレクトリには、macOS環境構築リポジトリ用の GitHub Actions ワークフローファイルが含まれています。

## ファイル構成

- **`environment_ci.yml`**: メインとなる統合CIパイプラインです。Pull Request作成時や`main`ブランチへのプッシュ時、または手動でトリガーされ、後述の他のワークフローを順次実行します。
- **`copilot-pr-review.yml`**: GitHub CopilotによるPRレビューをリクエストする再利用可能ワークフローです。
- **`run-setup-test.yml`**: macOS環境でのセットアップテスト (`.github/workflows/setup_test.sh`) を実行する再利用可能ワークフローです。
- **`notify-completion.yml`**: パイプラインの各ジョブの完了ステータスをPull Requestにコメントとして投稿する再利用可能ワークフローです。

## CIの特徴

### ワークフローの分割
メインの`environment_ci.yml`が、Copilotレビューリクエスト、セットアップテスト実行、完了通知といった個別の再利用可能ワークフローを呼び出す構造になっています。

### 環境セットアップの検証
Pull Requestや`main`ブランチへのプッシュ時に、`.github/workflows/setup_test.sh` スクリプトを実行し、macOS環境のセットアップが正しく行われるかを自動で検証します。

### Pull Request への自動フィードバック
Pull Requestに対して、以下の自動処理を行います:
- GitHub Copilotによる自動レビューリクエスト。
- パイプライン全体の完了ステータス通知（各ジョブの成否を示すサマリーコメント）。

## 機能詳細

### `environment_ci.yml` (メインパイプライン)

- **トリガー**: `main`へのPush、`main`ターゲットのPR、手動実行 (`workflow_dispatch`)
- **処理**:
    1. Copilotレビュー依頼 (PR時, `copilot-pr-review.yml`)
    2. macOSセットアップテスト実行 (`run-setup-test.yml`)
    3. パイプライン完了ステータス通知 (PR時, `notify-completion.yml`、全ジョブ完了後に実行)

### `copilot-pr-review.yml` (Copilotレビュー依頼)

- **トリガー**: `environment_ci.yml` から `workflow_call` で呼び出し (PR時)
- **処理**:
    1. 入力されたPR番号に対して `copilot` をレビュアーとして追加リクエスト。
    2. 失敗した場合、エラー理由を含むコメントをPRに投稿。

### `run-setup-test.yml` (セットアップテスト実行)

- **トリガー**: `environment_ci.yml` から `workflow_call` で呼び出し
- **処理**:
    1. リポジトリのチェックアウト (`actions/checkout@v4`)。
    2. GitHub認証の設定 (`git config`)。
    3. テストスクリプト (`setup_test.sh`, `verify_environment.sh`) に実行権限を付与 (`chmod +x`)。
    4. `setup_test.sh all` を実行し、環境セットアップをテスト。

### `notify-completion.yml` (完了通知)

- **トリガー**: `environment_ci.yml` から `workflow_call` で呼び出し (PR時、常に実行)
- **処理**:
    1. 各先行ジョブ (`request-copilot-review`, `run-macos-tests`) の結果を受け取る。
    2. 全体ステータスアイコンと各ジョブの成否を示すサマリーを構築。
    3. Pull Requestにサマリーコメント (`<!-- ci-status-summary -->`) を投稿または更新。

## 使用方法

メインパイプライン (`environment_ci.yml`) は以下のタイミングで自動実行されます:

- **プッシュ時**: `main` ブランチへのプッシュ
- **PR作成/更新時**: `main` ブランチをターゲットとするPull Request
- **手動実行**: GitHub Actionsタブから `environment_ci.yml` を選択して実行可能

個別のワークフローは通常、直接実行するのではなく、`environment_ci.yml` によって呼び出されます。

## 技術仕様

- **実行環境**: `macos-latest`
- **主要スクリプト**: 
    - `.github/workflows/setup_test.sh`
    - `.github/workflows/verify_environment.sh` 