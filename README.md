# MacOS Environment Setup

## Directory Structure

```
environment/
├── .github/
│   └── workflows/
├── config/
│   ├── brew/
│   ├── gems/
│   ├── git/
│   ├── macos/
│   ├── node/
│   ├── shell/
│   └── vscode/
├── scripts/
│   ├── cursor.sh
│   ├── flutter.sh
│   ├── git.sh
│   ├── homebrew.sh
│   ├── macos.sh
│   ├── node.sh
│   ├── ruby.sh
│   ├── shell.sh
│   └── vscode.sh
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

7.  **Cursor Configuration**
    -   `config/cursor/`から`$HOME/Library/Application Support/Cursor/User`への設定ファイルのシンボリックリンクを作成

8.  **VS Code Configuration**
    -   `config/vscode/`から`$HOME/Library/Application Support/Code/User`への設定ファイルのシンボリックリンクを作成

9.  **Python Environment Setup**
    -   `pyenv`をインストール
    -   特定のバージョンのPythonをインストールし、グローバルに設定

10. **Java Environment Setup**
    -   `Homebrew`を使用して特定のバージョンのJava (Temurin)をインストール

11. **Flutter Setup**

12. **GitHub CLI Configuration**

13. **SSH Key Management**
    -   SSHキーの存在確認
    -   SSHエージェントの設定

## Setup Instructions

### 1. Clone or Download the Repository

```sh
$ git clone git@github.com:akitorahayashi/environment.git
$ cd environment
```

### 2. Pre-setup Script

事前準備を行うスクリプトを実行します
特に初回は実行してください

```sh
$ chmod +x initial-setup.sh
$ ./initial-setup.sh
```

このスクリプトは以下を行います
- Xcode Command Line Tools のインストール
- SSH鍵の生成（存在しない場合）
- GitHubへのSSH鍵追加のガイド
- SSH接続のテスト
- 実行権限の付与

### 3. Run the Installation Script

```sh
$ ./install.sh
```

### 4. Individual Setup Scripts

`scripts/`内の各セットアップスクリプトは個別に実行できます

```sh
# Homebrewのセットアップ
$ ./scripts/homebrew.sh

# シェルの設定
$ ./scripts/shell.sh

# Gitの設定
$ ./scripts/git.sh

# Ruby環境のセットアップ
$ ./scripts/ruby.sh

# Python環境のセットアップ
$ ./scripts/python.sh

# Java環境のセットアップ
$ ./scripts/java.sh

# Flutterのセットアップ
$ ./scripts/flutter.sh

# Cursorの設定
$ ./scripts/cursor.sh

# VSCodeの設定
$ ./scripts/vscode.sh

# macOSの設定
$ ./scripts/macos.sh
```

各スクリプトは以下のように動作します
1. コンポーネントが既にインストール/設定されているかチェック
2. 必要な場合のみインストールまたは設定を実行
3. セットアップを検証

### 5. Apply Shell Configuration

スクリプトが完了したら、ターミナルを再起動するか、`source ~/.zprofile`を実行してシェル設定を適用してください

### 6. Configure GitHub CLI

スクリプト実行中にプロンプトが表示された場合、またはスキップした場合は、GitHub CLIを認証してください

### 7. Restart macOS

設定を完全に適用するために、macOSを再起動してください。

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

# グローバルに設定
$ rbenv global 3.2.2
```

## Python Development Environment

```bash
# 利用可能なPythonバージョンを表示
$ pyenv install -l

# バージョンをインストール
$ pyenv install 3.12.4

# グローバルに設定
$ pyenv global 3.12.4
```

## Java Development Environment

```bash
# インストールされたJavaのバージョンを確認
$ /usr/libexec/java_home -V
```