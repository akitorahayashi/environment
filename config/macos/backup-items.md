## 概要

このドキュメントは、`config/macos/backup_settings.sh` スクリプトでバックアップ可能な macOS の設定項目と、それに対応するコマンドの一覧です。

### システム

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write NSGlobalDomain AppleHighlightColor -string "R G B"` | アクセントカラー | `R G B` に `0.0`〜`1.0`の値をスペース区切りで指定し、クリックや選択範囲のハイライト色を変更します。 |
| `defaults write NSGlobalDomain AppleShowScrollBars -string "Always"` | スクロールバーの表示 | スクロールバーを常に表示するかどうかを指定します。（`WhenScrolling`, `Automatic`, `Always`） |
| `defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true` | 保存パネルのデフォルト展開 | ファイル保存時に出てくるダイアログ（保存パネル）を、最初から詳細表示（フォルダ選択やタグなどが見える状態）で開くようにします。通常はシンプル表示ですが、この設定で毎回詳細オプションが展開されます。 |
| `defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true` | 印刷パネルのデフォルト展開 | ファイル印刷時に表示されるダイアログ（印刷パネル）を、最初から詳細表示（プリンタ選択や用紙設定などが見える状態）で開くようにします。通常はシンプル表示ですが、この設定で毎回詳細オプションが展開されます。 |
| `defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false` | 書類をiCloudに保存 | `false`で新規作成した書類をデフォルトでローカルディスクに保存します。 |
| `defaults write com.apple.LaunchServices LSQuarantine -bool false` | アプリケーション起動時の確認ダイアログ | `false`で初回起動時に表示される「〜を開いてもよろしいですか？」の確認を無効化します。 |
| `defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false` | システムの復元機能（Resume） | `false`でアプリケーションを再起動した際に前回のウィンドウを復元する機能を無効化します。 |
| `defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true` | 非アクティブなアプリの自動終了 | `true`で、システムのメモリが圧迫された際に、OSが非アクティブと判断したアプリケーションを自動終了させる機能を無効化します。 |
| `defaults write com.apple.CrashReporter DialogType -string "none"` | クラッシュレポーター | `none`に設定すると、アプリケーションのクラッシュ時に表示されるレポート送信ダイアログを無効化します。 |

### UI/UX

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write NSGlobalDomain _HIHideMenuBar -bool true` | メニューバーの自動非表示 | `true`でメニューバーを自動的に隠します。 |
| `defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2` | サイドバーのアイコンサイズ | サイドバーに表示されるアイコンのサイズを指定します。（1: 小, 2: 中, 3: 大） |
| `defaults write NSGlobalDomain NSWindowResizeTime -float 0.001` | ウィンドウリサイズのアニメーション速度 | アプリケーションのウィンドウサイズを変更する際のアニメーション速度を調整します。（`0.01` など小さい値で高速化） |
| `defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false` | 自動大文字入力 | `false`で文頭の自動的な大文字化を無効にします。 |
| `defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false` | スマートダッシュ | `false`でハイフン2つ（--）がエムダッシュ（—）に自動変換されるのを防ぎます。 |
| `defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false` | 自動ピリオド入力 | `false`でスペース2回でピリオドが自動入力されるのを防ぎます。 |
| `defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false` | スマートクオート | `false`でストレートクオート（"）がタイポグラフィカルクオート（“”）に自動変換されるのを防ぎます。 |
| `defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false` | 自動スペル修正 | `false`で入力中の自動的なスペル修正を無効にします。 |
| `defaults write NSGlobalDomain WebKitDeveloperExtras -bool true` | Webインスペクタの有効化 | `true`でWeb開発用のインスペクタ機能を有効にします。 |
| `defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool false` | スワイプでのナビゲーション無効化 | `false`でトラックパッドやマウスのスワイプ操作による「戻る・進む」ジェスチャーを無効にします。 |


### Dock

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.dock tilesize -int 50` | Dockのサイズ | Dockに表示されるアイコンのサイズをピクセル単位で指定します。 |
| `defaults write com.apple.dock autohide -bool true` | Dockの自動非表示 | `true`でDockを自動的に隠します。 |
| `defaults write com.apple.dock autohide-time-modifier -float 0` | 自動非表示のアニメーション時間 | Dockが隠れたり表示されたりする際のアニメーション時間を秒単位で指定します。`0`でアニメーションを無効化します。 |
| `defaults write com.apple.dock autohide-delay -float 0` | 自動非表示の遅延 | マウスカーソルが画面端に達してからDockが表示されるまでの遅延を秒単位で指定します。 |
| `defaults write com.apple.dock show-recents -bool false` | 最近使用したアプリの表示 | `false`でDockに最近使用したアプリケーションのセクションを非表示にします。 |
| `defaults write com.apple.dock mineffect -string "scale"` | 最小化エフェクト | ウィンドウを最小化する際のアニメーションを指定します。（`genie` または `scale`） |
| `defaults write com.apple.dock minimize-to-application -bool true` | ウィンドウをアプリアイコンに最小化 | `true`でウィンドウを個別のサムネイルではなく、アプリケーションのアイコンに最小化します。 |
| `defaults write com.apple.dock static-only -bool true` | アクティブなアプリのみ表示 | `true`で起動中のアプリケーションのみをDockに表示します。 |
| `defaults write com.apple.dock scroll-to-open -bool true` | スクロールでExposé | `true`でDockのアイコン上でスクロールすると、そのアプリのExposé（App Exposé）を起動します。 |
| `defaults write com.apple.dock launchanim -bool false` | アプリケーション起動時のアニメーション | `false`でDockからアプリケーションを起動する際のジャンプアニメーションを無効化します。 |
| `defaults write com.apple.dock showhidden -bool true` | 非表示アプリのアイコンを半透明化 | `true`で非表示（Hidden）に設定されているアプリケーションのアイコンを半透明で表示します。 |
| `defaults write com.apple.dock no-bouncing -bool true` | アプリ起動時のアイコンバウンド | `true`でアプリケーション起動時のDockアイコンのバウンドを無効にします。 |

### Finder

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.finder ShowPathbar -bool true` | パスバーの表示 | `true`でFinderウィンドウ下部にファイルパスを表示するパスバーを有効にします。 |
| `defaults write com.apple.finder ShowStatusBar -bool true` | ステータスバーの表示 | `true`でFinderウィンドウ下部に空き容量や項目数を表示するステータスバーを有効にします。 |
| `defaults write com.apple.finder AppleShowAllFiles -bool true` | 隠しファイルの表示 | `true`で全ての隠しファイル・フォルダを表示します。 |
| `defaults write NSGlobalDomain AppleShowAllExtensions -bool true` | 全ての拡張子を表示 | `true`で全てのファイルの拡張子を表示します。 |
| `defaults write com.apple.finder _FXShowPosixPathInTitle -bool true` | ウィンドウタイトルにフルパス表示 | `true`でFinderウィンドウのタイトルバーに現在表示しているフォルダのフルパスを表示します。 |
| `defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"` | デフォルトの表示スタイル | Finderのデフォルト表示形式を指定します。（`icnv`: アイコン, `Nlsv`: リスト, `clmv`: カラム, `glyv`: ギャラリー） |
| `defaults write com.apple.finder _FXSortFoldersFirst -bool true` | フォルダを常に先頭に表示 | `true`でウィンドウ内およびデスクトップでフォルダをファイルより常に上に表示します。 |
| `defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"` | デフォルトの検索範囲 | Finderでの検索時にデフォルトで検索する範囲を指定します。（`SCcf`: 現在のフォルダ, `SCev`: このMac） |
| `defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false` | 拡張子変更時の警告 | `false`でファイル拡張子を変更する際の警告を無効にします。 |
| `defaults write com.apple.finder WarnOnEmptyTrash -bool false` | ゴミ箱を空にする前の警告 | `false`でゴミ箱を空にする際の確認ダイアログを無効にします。 |
| `defaults write com.apple.finder FXRemoveOldTrashItems -bool true` | 30日後にゴミ箱を空にする | `true`で30日以上ゴミ箱にある項目を自動的に削除します。 |
| `defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true` | `.DS_Store`ファイルの生成抑制 | ネットワークドライブやUSBメモリで `.DS_Store` ファイルが自動生成されるのを防ぎます。 |
| `defaults write com.apple.finder QuitMenuItem -bool true` | Finderの終了メニュー | `true`でFinderのメニューに「Finderを終了」の項目を追加します。 |
| `defaults write com.apple.finder DisableAllAnimations -bool true` | Finderのアニメーション効果 | `true`でFinderのウィンドウアニメーションや情報表示のアニメーションを無効化します。 |
| `defaults write NSGlobalDomain com.apple.springing.enabled -bool true` | スプリングローディング | ディレクトリ上でのドラッグ＆ドロップ操作におけるスプリングローディング（フォルダが自動で開く機能）を有効化・高速化します。 |

### デスクトップ

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false` | 外部ハードドライブのデスクトップへの表示 | USBやThunderbolt接続のディスクなどをデスクトップに表示するか|
| `defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool true` | デスクトップ表示のクリック挙動 | 通常のクリックでデスクトップ表示を有効化するかどうかを制御します。 |
| `defaults write com.apple.WindowManager GloballyEnabled -bool true` | ステージマネージャの有効化 | `true`でステージマネージャを有効にします。 |

### ミッションコントロール

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.dock expose-animation-duration -float 0.1` | アニメーションの高速化 | ミッションコントロールの表示・非表示アニメーションの速度を調整します。 |
| `defaults write com.apple.dock mru-spaces -bool false` | 操作スペースの自動並べ替え | `false`で最近使った操作スペースに基づいて自動的に並べ替える機能を無効にします。 |
| `defaults write com.apple.dock expose-group-by-app -bool false` | アプリごとにウィンドウをグループ化 | `false`でミッションコントロールでウィンドウをアプリケーションごとにグループ化しないようにします。（旧Exposéの挙動） |
| `defaults write com.apple.dock workspaces-auto-swoosh -bool true` | アプリ切り替え時にスペースを移動 | `true`でアプリケーションのウィンドウが含まれる操作スペースに自動で切り替えます。 |
| `defaults write com.apple.spaces spans-displays -bool true` | ディスプレイごとに個別の操作スペース | `true`で各ディスプレイに個別のメニューバーと操作スペースを持たせます。 |

### ホットコーナー

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.dock wvous-tl-corner -int 2` | ホットコーナーの設定 | 画面の四隅（tl:左上, tr:右上, bl:左下, br:右下）にカーソルを移動したときのアクションを割り当てます。 |

### キーボード

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write NSGlobalDomain KeyRepeat -int 1` | キーリピート速度 | キーを押し続けたときのリピート速度を調整します。（速いほど値が小さい） |
| `defaults write NSGlobalDomain InitialKeyRepeat -int 10` | キーリピート開始までの時間 | キーを押し続けてからリピートが開始されるまでの時間を調整します。（短いほど値が小さい） |
| `defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false` | キー長押しでのアクセント文字入力 | `false`でキーの長押しによるアクセント文字の入力を無効にし、キーリピートを有効にします。 |
| `defaults write NSGlobalDomain AppleKeyboardUIMode -int 3` | フルキーボードアクセス | モーダルダイアログ内のすべてのコントロール（ボタンなど）をTabキーで移動できるようにします。 |
| `defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false` | 「自然な」スクロール | `false`でコンテンツと指の動きが連動しない、従来のスクロール方向にします。 |
| `defaults write com.apple.keyboard.fnState -bool true` | ファンクションキーの動作 | `true`でF1, F2などのキーを標準のファンクションキーとして使用します。 |

### マウス

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write -g com.apple.mouse.scaling -float 3.0` | マウスの移動速度 | マウスカーソルの移動速度を調整します。 |
| `defaults write .GlobalPreferences com.apple.mouse.scaling 1` | マウス加速の無効化 | `-1`でマウス加速を完全に無効化し、リニアな動きになります。`0`は加速ほぼなし（非常に遅い）、`1`以上の正の値は加速あり（値が大きいほど加速・速度が速くなります）。 |
| `defaults write com.apple.Terminal FocusFollowsMouse -bool true` | マウスカーソル追従フォーカス | `true`でマウスカーソルをウィンドウ上に移動するだけでそのウィンドウをアクティブにします。（クリック不要） |

### トラックパッド

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write -g com.apple.trackpad.scaling -float 1.5` | トラックパッドの移動速度 | トラックパッドでのカーソル移動速度を調整します。 |
| `defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true` | タップでクリック | `true`でトラックパッドをタップしてクリックできるようにします。 |
| `defaults write com.apple.AppleMultitouchTrackpad Dragging -bool true` | タップでドラッグ | `true`でダブルタップから指を離さずにドラッグ操作ができるようにします。 |
| `defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true` | 3本指でドラッグ | `true`で3本指でウィンドウやオブジェクトをドラッグできるようにします。 |
| `defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1` | クリックの強さ | クリックに必要な圧力を調整します。（0: 弱い, 1: 中, 2: 強い） |
| `defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true` | Force Touch | `true`で感圧タッチ（Force Touch）を無効にします。 |
| `defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 2` | 3本指タップ | 3本指タップの動作を割り当てます。（0: 無効, 2: 辞書で調べる） |
| `defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true` | 2本指で右クリック | `true`で2本指でのクリックまたはタップを右クリックとして扱います。 |

### サウンド

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0` | UI操作音 | `0`でユーザーインターフェースの効果音を無効にします。 |
| `defaults write -g "com.apple.sound.beep.feedback" -int 0` | 音量変更時のフィードバック音 | `0`で音量を変更したときに再生される効果音を無効にします。 |
| `defaults write -g "com.apple.sound.beep.sound" -string "/path/to/sound.aiff"` | アラート音の種類 | システムのアラート音として使用するサウンドファイルを指定します。 |
| `defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40` | Bluetoothヘッドフォンの音質向上 | Bluetoothオーディオのビットプール値を調整し、音質を向上させます。 |

### スクリーンショット

| コマンド | 項目 | 説明 |
| :--- | :--- | :--- |
| `defaults write com.apple.screencapture location ~/Desktop` | 保存場所 | スクリーンショットが保存されるデフォルトの場所を指定します。 |
| `defaults write com.apple.screencapture disable-shadow -bool true` | 影を無効化 | `true`でウィンドウのスクリーンショットを撮る際に影を含めないようにします。 |
| `defaults write com.apple.screencapture include-date -bool true` | ファイル名に日付を含める | `true`でスクリーンショットのファイル名に撮影日時を含めます。 |
| `defaults write com.apple.screencapture show-thumbnail -bool false` | サムネイル表示 | `false`で撮影後に画面右下に表示されるフローティングサムネイルを無効にします。 |
| `defaults write com.apple.screencapture type -string "png"` | ファイルフォーマット | スクリーンショットの画像ファイル形式を指定します。（`png`, `jpg`, `gif`, `tiff`, `pdf`） |
