# MacOS Environment Setup

## Directory Structure

```
environment/
├── .github/
│   └── workflows/
├── macos/
│   ├── settings/
│   └── shell/
├── installers/
│   ├── config/
│   │   ├── brew/
│   │   ├── gems/
│   │   ├── git/
│   │   ├── node/
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
├── .gitignore
├── apply.sh
├── install.sh
└── README.md
```

## Implementation Features

1.  **Homebrew Setup**
    -   Homebrewと必要なコマンドラインツールのインストール

2.  **Shell Configuration**
    -   `config/shell/`から`$HOME`への`.zprofile`と`.zshrc`のシンボリックリンクを作成
    -   既存の`.zshrc`は上書きされます

3.  **Git Configuration**
    -   `config/git/.gitconfig`から`~/.config/git/config`へのコピーを作成
    -   Gitのエイリアスなどの設定を適用

4.  **macOS Settings**
    -   `config/macos/settings.sh`からトラックパッド、マウス、キーボード、Dock、Finder、スクリーンショットなどの設定を適用
    -   `config/macos/backup_settings.sh`で現在の設定をバックアップして設定ファイルを生成可能

5.  **Package Installation from Brewfile**
    -   `config/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

6.  **Ruby Environment Setup**
    -   `rbenv`と`ruby-build`をインストール
    -   特定のバージョンのRubyをインストールし、グローバルに設定
    -   `config/gems/global-gems.rb`に基づき、`bundler`を使用してgemをインストール

7.  **VS Code Configuration**
    -   `config/vscode/`から`$HOME/Library/Application Support/Code/User`への設定ファイルのシンボリックリンクを作成

8.  **Python Environment Setup**
    -   `pyenv`をインストール
    -   特定のバージョンのPythonをインストールし、グローバルに設定

9. **Java Environment Setup**
    -   `Homebrew`を使用して特定のバージョンのJava (Temurin)をインストール

10. **Node.js Environment Setup**
    -   `nvm`と`jq`をHomebrewでインストール
    -   特定のバージョンのNode.jsをインストールし、デフォルトとして設定
    -   `config/node/global-packages.json`に基づき、グローバルnpmパッケージをインストール

11. **Flutter Setup**

12. **GitHub CLI Configuration**

13. **SSH Key Management**
    -   SSHキーの存在確認
    -   SSHエージェントの設定

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

3.  **インストールスクリプトの実行**

    ```sh
    ./install.sh
    ```

4.  **Gitの個人設定**

    リポジトリのルートにある`.env.example`をコピーして`.env`ファイルを作成します。
    その後、`.env`ファイル内の`username`と`email`をご自身のものに編集してください。

    ```sh
    cp .env.example .env
    # .env ファイルを編集して、username と email を設定します
    ```

    `./install.sh` または `./installers/scripts/git.sh` を実行すると、`.env`ファイルの情報が自動的にGitのグローバル設定に反映されます。

5.  **macOSとシェルの設定を適用**

    ```sh
    ./apply.sh
    ```

6.  **GitHub CLIの認証**

    GitHub CLIを認証してください。

    ```sh
    # GitHub.comの認証を追加
    gh auth login

    # GitHub Enterpriseの認証を追加（該当する場合）
    gh auth login --hostname your-enterprise-hostname.com
    ```

7.  **macOSの再起動**

    設定を完全に適用するために、macOSを再起動してください。

## Individual Setup Scripts

### Main setup

`installers/scripts/`内の各セットアップスクリプトは個別に実行できます

```sh
# Homebrewのセットアップ
$ ./installers/scripts/homebrew.sh

# Gitの設定
$ ./installers/scripts/git.sh

# Ruby環境のセットアップ
$ ./installers/scripts/ruby.sh

# Python環境のセットアップ
$ ./installers/scripts/python.sh

# Java環境のセットアップ
$ ./installers/scripts/java.sh

# Node.js環境のセットアップ
$ ./installers/scripts/node.sh

# Flutterのセットアップ
$ ./installers/scripts/flutter.sh

# VSCodeの設定
$ ./installers/scripts/vscode.sh
```

各スクリプトは以下のように動作します
1. コンポーネントが既にインストール/設定されているかチェック
2. 必要な場合のみインストールまたは設定を実行
3. セットアップを検証

