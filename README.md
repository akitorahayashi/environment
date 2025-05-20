# MacOS Environment Setup

このツールは、開発環境のセットアップを自動化し、必要なツールを一括でインストールします。主に環境構築、複数のMacの環境統一、基本的な環境の状態確認に使用します

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
├── macos/
├── scripts/
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
    -   `stow`を使用して`config/git/`から`$HOME`への`.gitconfig`と`.gitignore_global`のシンボリックリンクを作成

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

13. **Neovim Configuration**
    -   `stow`を使用して`config/nvim/`から`$HOME/.config/nvim`へのNeovim設定のシンボリックリンクを作成

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

### 3. Update Git Configuration (Optional but Recommended)

インストールスクリプトを実行する前に、`config/git/.gitconfig`で名前とメールアドレスを更新することをお勧めします。

### 4. Run the Installation Script

```sh
$ ./install.sh
```

スクリプトは場所に依存せず、必要なファイルを自動的に検出します。Homebrew、`stow`、その他の依存関係が不足している場合は自動的にインストールされます。

### 5. Individual Setup Scripts

`scripts/setup/`内の各セットアップスクリプトは個別に実行できます。これらのスクリプトは冪等性を持ち、複数回安全に実行できます。使用方法は以下の通りです：

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

各スクリプトには以下が含まれています：
- 依存関係のチェック
- インストール/設定手順
- セットアップの検証
- 詳細なログ出力
- エラーハンドリング

スクリプトは以下のように動作します：
1. コンポーネントが既にインストール/設定されているかチェック
2. 必要な場合のみインストールまたは設定を実行
3. セットアップを検証
4. プロセスに関する詳細なフィードバックを提供

### 6. Apply Shell Configuration

スクリプトが完了したら、ターミナルを再起動するか、`source ~/.zprofile`を実行してシェル設定を適用してください。

### 7. Android Development Environment Setup

Flutterアプリ開発の場合は、Android Studioを起動し、画面の指示に従ってセットアップを完了してください。

### 8. SSH Key for GitHub

スクリプトは必要に応じてSSHキーを生成します。公開キー（`~/.ssh/id_ed25519.pub`）をGitHubアカウントに追加してください。

```sh
$ cat ~/.ssh/id_ed25519.pub
```

接続を確認：

```sh
$ ssh -T git@github.com
```

成功すると、以下のようなメッセージが表示されます：

```
Hi ${GITHUB_USERNAME}! You've successfully authenticated, but GitHub does not provide shell access.
```

### 9. Configure GitHub CLI

スクリプト実行中にプロンプトが表示された場合、またはスキップした場合は、GitHub CLIを認証してください：

```sh
# GitHub.comの認証を追加
$ gh auth login

# GitHub Enterpriseの認証を追加（該当する場合）
$ gh auth login --hostname your-enterprise-hostname.com
```

## Managing Configuration Files (Dotfiles)

このセットアップでは`config/`ディレクトリ内の設定ファイルを管理するために`stow`を使用しています。`stow`はこのリポジトリ内のファイルから、ホームディレクトリ内の期待される場所（例：`config/git/.gitconfig`から`$HOME/.gitconfig`）へのシンボリックリンクを作成します。

- 既存のツール（例：git）の新しい設定ファイルを追加するには、対応するディレクトリ（例：`config/git/`）に配置し、`./install.sh`を再実行してください。
- 新しいツールの設定を追加するには、`config/`の下に新しいディレクトリ（例：`config/mytool/`）を作成し、その中に設定ファイルを配置し、`install.sh`にセットアップステップ（おそらく`stow`を使用）を追加し、`scripts/setup/`に対応するセットアップスクリプトを追加してください。
- リンクされたファイルを直接変更した場合（例：Cursor UIで設定を変更）、このリポジトリ内のファイルが直接変更されます。これらの変更を保存するには、Gitにコミットしてください。

## Ruby Development Environment

```bash
# 利用可能なRubyバージョンを表示
$ rbenv install -l

# バージョンをインストール
$ rbenv install 3.2.2

# グローバルデフォルトとして設定
$ rbenv global 3.2.2
``` 