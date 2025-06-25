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
    -   `config/shell/`から`$HOME`への`.zprofile`と`.zshrc`のシンボリックリンクを作成
    -   既存の`.zshrc`は上書きされます

3.  **Git Configuration**
    -   `config/git/.gitconfig`を`~/.config/git/config`にコピー
    -   Gitのエイリアスなどの設定を適用

4.  **macOS Settings**
    -   トラックパッド、マウス、キーボード、Dock、Finder、スクリーンショットなどの設定を適用

5.  **Package Installation from Brewfile**
    -   `config/brew/Brewfile`に記載されたパッケージを`brew bundle`を使用してインストール

6.  **Ruby Environment Setup**

7.  **Xcode Installation and Setup**

8.  **Cursor Configuration**
    -   `config/cursor/`から`$HOME/Library/Application Support/Cursor/User`への設定ファイルのシンボリックリンクを作成

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

### 2. SSH Key Generation (Required)

スクリプト実行前に、SSHキーを手動で生成してください：

```sh
# GitHubで使用するメールアドレスを指定してSSHキーを生成
$ ssh-keygen -t ed25519 -C "your_email@example.com"

# SSHエージェントを開始
$ eval "$(ssh-agent -s)"

# SSHキーをエージェントに追加
$ ssh-add ~/.ssh/id_ed25519

# 公開キーをクリップボードにコピー
$ pbcopy < ~/.ssh/id_ed25519.pub
```

生成後、[GitHub SSH Keys設定](https://github.com/settings/keys)で公開キーを追加してください。

### 3. Grant Execution Permission

```sh
$ chmod +x install.sh
$ chmod +x scripts/setup/*.sh
```

### 4. Run the Installation Script

```sh
$ ./install.sh
```

### 5. Individual Setup Scripts

`scripts/setup/`内の各セットアップスクリプトは個別に実行でき、冪等性を持ち、複数回安全に実行できます

```sh
# HomebrewとXcode Command Line Toolsのセットアップ
$ ./scripts/setup/homebrew.sh

# シェルの設定
$ ./scripts/setup/shell.sh

# Gitの設定
$ ./scripts/setup/git.sh

# Ruby環境のセットアップ
$ ./scripts/setup/ruby.sh

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

### 6. Apply Shell Configuration

スクリプトが完了したら、ターミナルを再起動するか、`source ~/.zprofile`を実行してシェル設定を適用してください

### 7. Android Development Environment Setup

Flutterアプリ開発の場合は、Android Studioを起動し、画面の指示に従ってセットアップを完了してください

### 8. Verify SSH Connection to GitHub

SSHキーが正しく設定されているか確認してください：

```sh
$ ssh -T git@github.com
```

成功すると、以下のようなメッセージが表示されます

```
Hi ${GITHUB_USERNAME}! You've successfully authenticated, but GitHub does not provide shell access.
```

### 9. Git User Configuration

スクリプト実行後、Gitのユーザー情報を設定してください：

```sh
# Gitユーザー名を設定
$ git config --global user.name "あなたの名前"

# Gitメールアドレスを設定（SSHキー生成時と同じメールアドレスを推奨）
$ git config --global user.email "あなたのメールアドレス"

# 設定の確認
$ git config --global user.name
$ git config --global user.email
```

### 10. Configure GitHub CLI

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