# MacOS Environment Setup

これは開発環境を自動で構築するためのツールです。自分の開発に必要なツールを一括インストールします。複数マシン間での環境の統一や、ベースの環境の状態も確認できます。

## Directory Structure

```
environment/
├── .github/        
│   └── workflows/  
│       ├── ci.yml         
│       ├── ci.yml    
│       └── setup_test.sh  
├── config/         
│   ├── Brewfile           
│   ├── global-packages.json 
│   └── global-gems.rb     
├── cursor/         
├── git/            
│   ├── .gitconfig
│   └── .gitignore_global
├── macos/          
├── scripts/        
│   ├── setup/      
│   │   ├── android.sh      
│   │   ├── cursor.sh       
│   │   ├── flutter.sh      
│   │   ├── git.sh          
│   │   ├── homebrew.sh     
│   │   ├── mac.sh          
│   │   ├── reactnative.sh  
│   │   ├── ruby.sh         
│   │   ├── shell.sh        
│   │   └── xcode.sh        
│   └── utils/      
│       ├── helpers.sh      
│       └── logging.sh      
├── shell/          
│   └── .zprofile
└── install.sh      
```

## Implementation Features

`install.sh`スクリプトは以下の機能を実装しています：

1. **Rosetta 2 Installation**
   - Apple Silicon 向け Intel ベースのアプリケーションの実行用

2. **Homebrew Setup**
   - 未インストールの場合にインストール

3. **Shell Configuration**
   - `.zprofile`のシンボリックリンクを作成

4. **Git Configuration**
   - `git/.gitconfig`と`git/.gitignore_global`のシンボリックリンクを作成

5. **macOS Settings**
   - トラックパッド、マウス、キーボード、Dock、Finder、スクリーンショットの設定を適用

6. **Package Installation from Brewfile**
   - `config/Brewfile`に記載されたパッケージを`brew bundle`でインストール
   - CLIツール、開発ツール、アプリケーションを含む

7. **Ruby Environment Setup**

8. **Xcode Installation and Setup**

9. **SwiftLint Installation**

10. **Flutter Configuration**

11. **React Native Environment Setup**
    - Node.js、Watchman、その他の必要な依存関係をインストール
    - iOSとAndroidの開発環境を設定

12. **GitHub CLI Configuration**

13. **SSH Key Generation**
    - SSH鍵が存在しない場合は生成
    - SSHエージェントを設定

14. **Cursor Configuration**
    - 設定のバックアップと復元機能を提供

## Setup Instructions

### 1. Clone or Download the Repository

```sh
$ git clone git@github.com:akitorahayashi/environment.git
$ cd environment
```

### 2. Grant Execution Permission
```sh
$ chmod +x install.sh
```

### 3. Update Git Configuration
インストールスクリプトを実行する前に、`git/.gitconfig`で名前とメールアドレスを更新してください。

### 4. Run the Installation Script
```sh
$ ./install.sh
```

スクリプトは場所に依存せず、必要なファイルを見つけるために自動的にパスを検出します。

### 5. Android Development Environment Setup

FlutterとReact Nativeアプリ開発のため：

```sh
# Android Studioを起動
$ open -a "Android Studio"
```

これによりAndroid SDK、プラットフォーム、ビルドツール、エミュレータのセットアップが構成されます。

### 6. React Native Development

インストール後：

```sh
# 新しいReact Nativeプロジェクトを作成
$ npx react-native init MyApp

# プロジェクトに移動
$ cd MyApp

# iOSで実行
$ npx react-native run-ios

# Androidで実行
$ npx react-native run-android
```

#### Environment Diagnostics

```sh
# React Native環境のセットアップを検証
$ ./scripts/setup/reactnative.sh

# 診断を個別に実行
$ npx react-native doctor
```

### 7. SSH Key for GitHub
スクリプトは必要に応じてSSH鍵を生成します。GitHubアカウントに追加してください：
```sh
$ cat ~/.ssh/id_ed25519.pub
```

接続を確認：
```sh
$ ssh -T git@github.com
```

### 8. Configure GitHub CLI
GitHub.comまたはGitHub Enterpriseで認証できます：
```sh
# GitHub.com認証を追加
$ gh auth login

# GitHub Enterprise認証を追加
$ gh auth login --hostname your-enterprise-hostname.com
```

## Cursor Settings Backup and Restore

```bash
# バックアップ
$ ./cursor/backup_cursor_settings.sh

# 復元
$ ./cursor/restore_cursor_settings.sh
```

## Ruby Development Environment

```bash
# 利用可能なRubyバージョンを一覧表示
$ rbenv install -l

# バージョンをインストール
$ rbenv install 3.2.2

# グローバルデフォルトとして設定
$ rbenv global 3.2.2
```

