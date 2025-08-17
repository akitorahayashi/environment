# MacOS Environment Setup

## Directory Structure

```
.
├── .github/
│   └── workflows/
├── config/
│   ├── common/
│   │   ├── brew/
│   │   ├── git/
│   │   ├── node/
│   │   ├── python/
│   │   ├── ruby/
│   │   ├── shell/
│   │   ├── system-defaults/
│   │   └── vscode/
│   ├── mac-mini-only/
│   │   ├── brew/
│   │   └── shell/
│   └── macbook-only/
│       ├── brew/
│       └── shell/
├── scripts/
│   ├── node/
│   │   ├── packages.sh
│   │   └── platform.sh
│   ├── python/
│   │   ├── platform.sh
│   │   └── tools.sh
│   ├── system-defaults/
│   │   ├── apply-system-defaults.sh
│   │   └── backup-system-defaults.sh
│   ├── flutter.sh
│   ├── git.sh
│   ├── homebrew.sh
│   ├── java.sh
│   ├── link-shell.sh
│   ├── ruby.sh
│   └── vscode.sh
├── .gitignore
├── Makefile
└── README.md
```

## Implementation Features

1.  **Homebrew Setup**
    -   Homebrewと必要なコマンドラインツールのインストール

2.  **Shell Configuration**
    -   `make link-shell` を実行することで、`config/common/shell/` 内の `.zprofile` と `.zshrc` がホームディレクトリにシンボリックリンクされます。

3.  **Git Configuration**
    -   `config/common/git/.gitconfig`から`~/.gitconfig`へのコピーを作成
    -   Gitのエイリアスなどの設定を適用

4.  **macOS Settings**
    -   `make apply-defaults` を実行することで、`config/common/system-defaults/system-defaults.sh` に基づいてシステム設定（system defaults）が適用されます。
    -   `make backup-defaults` を実行することで、現在のmacOSの system defaults を生成/更新します（内部的に `scripts/backup-system-defaults.sh` を呼び出します）。

5.  **Package Installation from Brewfile**
    -   `config/common/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

6.  **Ruby Environment Setup**
    -   `rbenv`と`ruby-build`をインストール
    -   特定のバージョンのRubyをインストールし、グローバルに設定
    -   `config/common/ruby/global-gems.rb`に基づき、`bundler`を使用してgemをインストール

7.  **VS Code Configuration**
    -   `config/common/vscode/`から`$HOME/Library/Application Support/Code/User`への設定ファイルのシンボリックリンクを作成

8.  **Python Environment Setup**
    -   `pyenv`をインストール
    -   特定のバージョンのPythonをインストールし、グローバルに設定

9. **Java Environment Setup**
    -   `Homebrew`を使用して特定のバージョンのJava (Temurin)をインストール

10. **Node.js Environment Setup**
    -   `nvm`と`jq`をHomebrewでインストール
    -   特定のバージョンのNode.jsをインストールし、デフォルトとして設定
    -   `config/common/node/global-packages.json`に基づき、グローバルnpmパッケージをインストール

11. **Flutter Setup**

## How to Use

`make` コマンドを使用して、セットアップを実行します。

- **`make` or `make help`**: 利用可能なすべてのコマンドとその説明を表示します。
- **`make macbook`**: MacBook用のすべてのセットアップスクリプトを順番に実行します。
- **`make mac-mini`**: Mac mini用のすべてのセットアップスクリプトを順番に実行します。
- **`make common`**: 共通設定ですべてのセットアップスクリプトを順番に実行します。
- **`make <command>`**: 個別のセットアップスクリプト（例: `make brew`, `make git`）を実行します。

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
    その後、`.env`ファイル内の`GIT_USERNAME`と`GIT_EMAIL`をご自身のものに編集してください。

    ```sh
    cp .env.example .env
    # .env ファイルを編集して、GIT_USERNAME と GIT_EMAIL を設定します
    ```
    この`.env`ファイルは、次のステップで実行される `make macbook` または `make git` によって自動的に読み込まれ、Gitのグローバル設定に反映されます。

4.  **各種ツールとパッケージのインストール**

    お使いのMacに合わせて、以下のいずれかのコマンドを実行してください。

    **MacBookの場合:**
    ```sh
    make macbook
    ```

    **Mac miniの場合:**
    ```sh
    make mac-mini
    ```
    このコマンドは、Homebrew、Git、Ruby、Python、Node.jsなど、開発に必要なツールを一括でインストールし、macOSとシェルの設定も適用します。

5.  **GitHub CLIの認証**

    `make macbook` または `make mac-mini` でGitHub CLI (`gh`) がインストールされた後、以下のコマンドで認証を行ってください。

    ```sh
    # GitHub.comの認証を追加
    gh auth login

    # GitHub Enterpriseの認証を追加（該当する場合）
    gh auth login --hostname your-enterprise-hostname.com
    ```

6.  **macOSの再起動**

    すべての設定を完全に適用するために、macOSを再起動してください。
