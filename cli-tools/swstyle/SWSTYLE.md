# `swstyle` コマンド

## 概要

`swstyle` コマンドは、標準的な SwiftLint と SwiftFormat の設定ファイルを現在のディレクトリにコピーするためのツールです。

## セットアップ

`environment` リポジトリの `./install.sh` を実行する過程で、`install.sh` が `~/bin` ディレクトリ内に `environment/cli-tools/swstyle/swstyle` スクリプトへのシンボリックリンクを作成し、実行権限を付与します。これにより、`~/bin/swstyle` としてコマンドが利用可能になります。

## 使い方

Swift プロジェクトまたは Playground の ルートディレクトリ に `cd` コマンドで移動し、以下のコマンドを実行します。

第一引数として、設定ファイルのタイプ (`project` または `playground`) を指定する必要があります。

```bash
# プロジェクト用設定をコピーする場合
cd /path/to/your/swift/project
swstyle project

# Playground用設定をコピーする場合
cd /path/to/your/playground
swstyle playground
```

### 動作

コマンドを実行すると、以下の処理が行われます：

1.  指定されたタイプ (`project` または `playground`) に応じて、`environment/cli-tools/swstyle/template/` 内の対応するサブディレクトリを参照します。
2.  そのサブディレクトリ内にある `.swiftlint.yml` および `.swiftformat` ファイルを、コマンドを実行したカレントディレクトリにコピーします。
3.  もしカレントディレクトリに同名のファイルが既に存在する場合、テンプレートファイルで **上書き** されます。