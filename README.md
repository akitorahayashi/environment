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
│   │   └── brew/
│   └── macbook-only/
│       ├── brew/
│       ├── node/
│       └── python/
├── scripts/
│   ├── node/
│   │   ├── platform.sh
│   │   └── tools.sh
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
    -   `make shell` を実行すると、共通のシェル設定（`.zprofile` と `.zshrc`）がホームディレクトリにシンボリックリンクされます。
    -   この設定は `config/common/shell/` にあります。

3.  **Git Configuration**
    -   `scripts/git.sh` を実行し、Gitの基本設定を行います。
    -   これには `.gitconfig` のコピー、グローバルな `.gitignore` の設定、`.env` ファイルからのユーザー情報（名前、メールアドレス）の設定が含まれます。

4.  **GitHub CLI (gh) Configuration**
    -   `scripts/gh.sh` を実行し、GitHub CLI (`gh`) の設定を行います。
    -   これには `gh` のインストールと、コマンドエイリアスの設定が含まれます。エイリアスは `.zshrc` でのシェルエイリアスではなく、`gh alias set` コマンドで管理されます。

5.  **macOS Settings**
    -   `make apply-defaults` を実行することで、`scripts/system-defaults/apply-system-defaults.sh` に基づいてシステム設定（system defaults）が適用されます。
    -   `make backup-defaults` を実行することで、現在のmacOSの system defaults を生成/更新します（内部的に `scripts/system-defaults/backup-system-defaults.sh` を呼び出します）。

6.  **Package Installation from Brewfile**
    -   `config/common/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

7.  **Ruby Environment Setup**
    -   `rbenv`と`ruby-build`をインストール
    -   特定のバージョンのRubyをインストールし、グローバルに設定
    -   `config/common/ruby/global-gems.rb`に基づき、`bundler`を使用してgemをインストール

8.  **VS Code Configuration**
    -   `config/common/vscode/`から`$HOME/Library/Application Support/Code/User`への設定ファイルのシンボリックリンクを作成

9.  **Python Environment Setup**
    -   `pyenv`をインストール
    -   特定のバージョンのPythonをインストールし、グローバルに設定

10. **Java Environment Setup**
    -   `Homebrew`を使用して特定のバージョンのJava (Temurin)をインストール

11. **Node.js Environment Setup**
    -   `nvm`と`jq`をHomebrewでインストール
    -   特定のバージョンのNode.jsをインストールし、デフォルトとして設定
    -   `config/common/node/global-packages.json`に基づき、グローバルnpmパッケージをインストール

12. **Flutter Setup**

## How to Use

`make` コマンドを使用して、セットアップを実行します。

- **`make` or `make help`**: 利用可能なすべてのコマンドとその説明を表示します。

### フルセットアップ

- **`make macbook`**: MacBook用のすべてのセットアップスクリプトを順番に実行します。
- **`make mac-mini`**: Mac mini用のすべてのセットアップスクリプトを順番に実行します。

### 個別・共通タスクの実行

- **`make common`**: 共通設定のみ（Git, VS Code, Ruby, Python, Java, Flutter, Node.js, Shell, System Defaults）をすべて実行します。
- **`make <task>`**: 個別のセットアップを実行します。
  - **共通タスク**: `make git`, `make shell`, `make java` など、特定の共通タスクを実行できます。
  - **マシン固有タスク**: `make macbook-brew`, `make mac-mini-brew` など、マシン固有のタスクも個別に実行可能です。

## Setup Instructions

1.  **Xcode Command Line Tools のインストール**

    ```sh
    xcode-select --install
    ```

2.  **Gitの個人設定 (`.env`ファイル作成)**

    リポジトリのルートにある`.env.example`をコピーして`.env`ファイルを作成します。
    その後、`.env`ファイル内の`GIT_USERNAME`と`GIT_EMAIL`をご自身のものに編集してください。

    ```sh
    cp .env.example .env
    # .env ファイルを編集して、GIT_USERNAME と GIT_EMAIL を設定します
    ```
    この`.env`ファイルは、次のステップで実行される `make macbook` または `make git` によって自動的に読み込まれ、Gitのグローバル設定に反映されます。

3.  **各種ツールとパッケージのインストール**

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

4.  **GitHub CLIの認証**

    `make macbook` または `make mac-mini` でGitHub CLI (`gh`) がインストールされた後、以下のコマンドで認証を行ってください。

    ```sh
    # GitHub.comの認証を追加
    gh auth login

    # GitHub Enterpriseの認証を追加（該当する場合）
    gh auth login --hostname your-enterprise-hostname.com
    ```

5.  **macOSの再起動**

    すべての設定を完全に適用するために、macOSを再起動してください。
