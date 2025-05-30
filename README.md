# MacOS Environment Setup

## Directory Structure

```
environment/
├── .github/
│   └── workflows/
├── config/
│   ├── brew/
│   ├── cursor/
│   ├── gems/
│   ├── git/
│   ├── node/
│   └── shell/
├── scripts/
│   ├── macos/
│   ├── setup/
│   └── utils/
├── .gitignore
├── install.sh
└── README.md
```

## Implementation Features

1.  **Homebrew Setup**
    -   Homebrewと必要なコマンドラインツールのインストール

2.  **Shell Configuration**
    -   `stow`を使用して`config/shell/`から`$HOME`への`.zprofile`のシンボリックリンクを作成

3.  **Git Configuration**
    -   `config/git/.gitconfig`から`~/.config/git/config`へのシンボリックリンクを作成
    -   Gitのエイリアスなどの設定を適用

4.  **macOS Settings**
    -   トラックパッド、マウス、キーボード、Dock、Finder、スクリーンショットなどの設定を適用

5.  **Package Installation from Brewfile**
    -   `config/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

6.  **Ruby Environment Setup**

7.  **Xcode Installation and Setup**

8.  **Cursor Configuration**
    -   `stow`を使用して`config/cursor/`から`$HOME/Library/Application Support/Cursor/User`への設定ファイル（`settings.json`、`keybindings.json`など）のシンボリックリンクを作成

9.  **Flutter Setup**

10. **React Native Setup** (実装を確認してください)

11. **GitHub CLI Configuration**

12. **SSH Key Generation**
    -   SSHキー（`id_ed25519`）が存在しない場合に生成
    -   SSHエージェントの設定

## Setup Instructions

### 1. Clone or Download the Repository

```sh
$ git clone git@github.com:akitorahayashi/environment.git
$ cd environment
```

### 2. Grant Execution Permission

```sh
$ chmod +x install.sh
$ chmod +x scripts/setup/*.sh
```

### 3. Run the Installation Script

```sh
$ ./install.sh
```

### 4. Individual Setup Scripts

`scripts/setup/`内の各セットアップスクリプトは個別に実行でき、冪等性を持ち、複数回安全に実行できます

```sh
# Homebrewのセットアップ
$ ./scripts/setup/homebrew.sh

# シェルの設定
$ ./scripts/setup/shell.sh

# Gitの設定
$ ./scripts/setup/git.sh

# Ruby環境のセットアップ
$ ./scripts/setup/ruby.sh

# Xcodeのセットアップ
$ ./scripts/setup/xcode.sh

# Flutterのセットアップ
$ ./scripts/setup/flutter.sh

# Cursorの設定
$ ./scripts/setup/cursor.sh

# macOSの設定
$ ./scripts/setup/mac.sh
```

各スクリプトは以下のように動作します
1. コンポーネントが既にインストール/設定されているかチェック
2. 必要な場合のみインストールまたは設定を実行
3. セットアップを検証

### 5. Apply Shell Configuration

スクリプトが完了したら、ターミナルを再起動するか、`source ~/.zprofile`を実行してシェル設定を適用してください

### 6. Android Development Environment Setup

Flutterアプリ開発の場合は、Android Studioを起動し、画面の指示に従ってセットアップを完了してください

### 7. SSH Key for GitHub

スクリプトは必要に応じてSSHキーを生成します。公開キー（`~/.ssh/id_ed25519.pub`）をGitHubアカウントに追加してください

```sh
$ cat ~/.ssh/id_ed25519.pub
```

接続を確認：

```sh
$ ssh -T git@github.com
```

成功すると、以下のようなメッセージが表示されます

```
Hi ${GITHUB_USERNAME}! You've successfully authenticated, but GitHub does not provide shell access.
```

### 8. Configure GitHub CLI

スクリプト実行中にプロンプトが表示された場合、またはスキップした場合は、GitHub CLIを認証してください

```sh
# GitHub.comの認証を追加
$ gh auth login

# GitHub Enterpriseの認証を追加（該当する場合）
$ gh auth login --hostname your-enterprise-hostname.com
```

## Ruby Development Environment

```bash
# 利用可能なRubyバージョンを表示
$ rbenv install -l

# バージョンをインストール
$ rbenv install 3.2.2

# グローバルデフォルトとして設定
$ rbenv global 3.2.2
``` 