# MacOS Environment Setup

## Directory Structure

```
environment/
├── .github/
│   └── workflows/
├── installers/
│   ├── config/
│   │   ├── brew/
│   │   ├── gems/
│   │   ├── git/
│   │   ├── node/
│   │   ├── python/
│   │   └── vscode/
│   └── scripts/
│       ├── flutter.sh
│       ├── git.sh
│       ├── homebrew.sh
│       ├── java.sh
│       ├── node.sh
│       ├── python.sh
│       ├── ruby.sh
│       └── vscode.sh
├── macos/
│   ├── config/
│   │   ├── settings/
│   │   └── shell/
│   └── scripts/
│       ├── backup_settings.sh
│       ├── apply-settings.sh
│       └── link-shell.sh
├── .gitignore
├── Makefile
└── README.md
```

## Implementation Features

1.  **Homebrew Setup**
    -   Homebrewと必要なコマンドラインツールのインストール

2.  **Shell Configuration**
    -   `make link-shell` を実行することで、`macos/config/shell/` 内の `.zprofile` と `.zshrc` がホームディレクトリにシンボリックリンクされます。

3.  **Git Configuration**
    -   `installers/config/git/.gitconfig`から`~/.gitconfig`へのコピーを作成
    -   Gitのエイリアスなどの設定を適用

4.  **macOS Settings**
    -   `make apply-settings` を実行することで、`macos/config/settings/macos-settings.sh` に基づいてシステム設定が適用されます。
    -   `make backup-settings` を実行することで、現在のmacOS設定を `macos-settings.sh` にバックアップできます。

5.  **Package Installation from Brewfile**
    -   `installers/config/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

6.  **Ruby Environment Setup**
    -   `rbenv`と`ruby-build`をインストール
    -   特定のバージョンのRubyをインストールし、グローバルに設定
    -   `installers/config/gems/global-gems.rb`に基づき、`bundler`を使用してgemをインストール

7.  **VS Code Configuration**
    -   `installers/config/vscode/`から`$HOME/Library/Application Support/Code/User`への設定ファイルのシンボリックリンクを作成

8.  **Python Environment Setup**
    -   `pyenv`をインストール
    -   特定のバージョンのPythonをインストールし、グローバルに設定

9. **Java Environment Setup**
    -   `Homebrew`を使用して特定のバージョンのJava (Temurin)をインストール

10. **Node.js Environment Setup**
    -   `nvm`と`jq`をHomebrewでインストール
    -   特定のバージョンのNode.jsをインストールし、デフォルトとして設定
    -   `installers/config/node/global-packages.json`に基づき、グローバルnpmパッケージをインストール

11. **Flutter Setup**

12. **GitHub CLI Configuration**

13. **SSH Key Management**
    -   SSHキーの存在確認
    -   SSHエージェントの設定

## How to Use

`make` コマンドを使用して、セットアップを実行します。

- **`make` or `make help`**: 利用可能なすべてのコマンドとその説明を表示します。
- **`make macbook`**: すべてのセットアップスクリプトを順番に実行します。
- **`make <command>`**: 個別のセットアップスクリプト（例: `make homebrew`, `make git`）を実行します。

## Setup Instructions

1.  **Xcode Command Line Tools のインストール**

    ```sh
    xcode-select --install
    ```

2.  **SSH鍵の生成とGitHubへの登録**

    SSH鍵がまだない場合は生成します。

    ```sh
    # メールアドレスを自分のものに置き換えてください
    ssh-keygen -t ed25519 -C "your_email@example.com"

    # macOS で SSH エージェントとキーチェーンへ登録（再起動後も保持）
    eval "$(ssh-agent -s)"
    /usr/bin/ssh-add --apple-use-keychain ~/.ssh/id_ed25519
    # 必要に応じて ~/.ssh/config を作成
    cat <<'EOF' >> ~/.ssh/config
    Host github.com
        AddKeysToAgent yes
        UseKeychain yes
        IdentityFile ~/.ssh/id_ed25519
    EOF
    ```

    生成された公開鍵 (`~/.ssh/id_ed25519.pub`) をコピーし、[GitHubのSSHキー設定ページ](https://github.com/settings/keys)に追加します。

    ```sh
    # 公開鍵をクリップボードにコピー
    pbcopy < ~/.ssh/id_ed25519.pub
    ```

    以下のコマンドでGitHubへの接続をテストします。

    ```sh
    ssh -T git@github.com
    ```

    "successfully authenticated" というメッセージが表示されれば成功です。

3.  **Gitの個人設定 (`.env`ファイル作成)**

    リポジトリのルートにある`.env.example`をコピーして`.env`ファイルを作成します。
    その後、`.env`ファイル内の`username`と`email`をご自身のものに編集してください。

    ```sh
    cp .env.example .env
    # .env ファイルを編集して、username と email を設定します
    ```
    この`.env`ファイルは、次のステップで実行される `make macbook` または `make git` によって自動的に読み込まれ、Gitのグローバル設定に反映されます。

4.  **各種ツールとパッケージのインストール**

    ```sh
    make macbook
    ```
    このコマンドは、Homebrew、Git、Ruby、Python、Node.jsなど、開発に必要なツールを一括でインストールします。

5.  **macOSとシェルの設定を適用**

    ```sh
    # シェル設定のシンボリックリンクを作成
    make link-shell

    # macOS システム設定を適用
    make apply-settings
    ```

6.  **GitHub CLIの認証**

    `make macbook`でGitHub CLI (`gh`) がインストールされた後、以下のコマンドで認証を行ってください。

    ```sh
    # GitHub.comの認証を追加
    gh auth login

    # GitHub Enterpriseの認証を追加（該当する場合）
    gh auth login --hostname your-enterprise-hostname.com
    ```

7.  **macOSの再起動**

    すべての設定を完全に適用するために、macOSを再起動してください。
