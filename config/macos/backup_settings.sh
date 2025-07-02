#!/bin/bash

# ================================================
# 現在の macOS の設定を取得し、settings.sh を生成
# ================================================
#
# Usage:
# 1. Grant execution permission:
#    $ chmod +x config/macos/backup_settings.sh
# 2. Run the script:
#    $ ./config/macos/backup_settings.sh
#
# The script will create/update config/macos/settings.sh with current macOS settings.
#
# ================================================

# ================================================
# 初期設定・ファイルパスの設定
# ================================================

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENVIRONMENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

OUTPUT_FILE="$SCRIPT_DIR/settings.sh"

echo "現在の macOS の設定を取得し、$OUTPUT_FILE を生成します..."

# 既存の設定ファイルを削除
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "既存の設定ファイルを削除しました: $OUTPUT_FILE"
fi

# 設定スクリプトのヘッダーを作成
cat <<EOF > "$OUTPUT_FILE"
#!/bin/bash

echo "Mac のシステム設定を適用中..."
EOF

# ================================================
# ユーティリティ関数の定義
# ================================================

# 値を取得し、存在しない場合はデフォルト値にフォールバックする関数
get_default_value() {
    local value
    value=$(defaults read "$1" "$2" 2>/dev/null || echo "$3")
    [[ -z "$value" ]] && value="$3"
    echo "$value"
}

# bool値を適切な形式に変換する関数
format_bool_value() {
    local value="$1"
    case "$value" in
        1|true) echo "true" ;;
        0|false) echo "false" ;;
        *) echo "$value" ;;
    esac
}

# 設定をファイルに追加する関数
add_setting() {
    local section_name="$1"
    local commands="$2"
    
    echo "# ${section_name}" >> "$OUTPUT_FILE"
    echo "${commands}" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
}

# ================================================
# 現在の設定値を取得
# ================================================

# トラックパッドの設定値を取得
TRACKPAD_SPEED=$(get_default_value -g com.apple.trackpad.scaling 1.5)          # トラックパッドのカーソル移動速度 (0.0-3.0)
TAP_TO_CLICK=$(get_default_value com.apple.AppleMultitouchTrackpad Clicking 1) # タップでクリック (1:有効, 0:無効)
DRAGGING=$(get_default_value com.apple.AppleMultitouchTrackpad Dragging 0)     # タップでドラッグ (1:有効, 0:無効)
THREE_FINGER_DRAG=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 0) # 3本指ドラッグ (1:有効, 0:無効)
FIRST_CLICK_THRESHOLD=$(get_default_value com.apple.AppleMultitouchTrackpad FirstClickThreshold 1)  # クリック圧の強さ - 弱 (0:弱, 1:中, 2:強)
SECOND_CLICK_THRESHOLD=$(get_default_value com.apple.AppleMultitouchTrackpad SecondClickThreshold 1) # クリック圧の強さ - 強 (0:弱, 1:中, 2:強)
FORCE_SUPPRESSED=$(get_default_value com.apple.AppleMultitouchTrackpad ForceSuppressed false)       # Force Touch (false:有効, true:無効)
THREE_FINGER_TAP=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture 0) # 3本指タップ (0:無効, 2:有効)
RIGHT_CLICK=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadRightClick true)          # 2本指クリックで右クリック (true:有効, false:無効)

# システムサウンドの設定値を取得
STARTUP_SOUND=$(get_default_value com.apple.systemsound "com.apple.sound.beep.flash" false)    # 起動時のサウンド (true:有効, false:無効)
UI_SOUND=$(get_default_value com.apple.systemsound "com.apple.sound.uiaudio.enabled" false)    # UI操作音 (true:有効, false:無効)
VOLUME_FEEDBACK=$(get_default_value -g "com.apple.sound.beep.feedback" false)                  # 音量変更時の効果音 (true:有効, false:無効)
ALERT_SOUND=$(get_default_value -g "com.apple.sound.beep.sound" "/System/Library/Sounds/Boop.aiff") # アラート音の種類

# Dockの設定値を取得
DOCK_SIZE=$(get_default_value com.apple.dock tilesize 50)           # Dockのサイズ (ピクセル)
DOCK_AUTOHIDE=$(get_default_value com.apple.dock autohide false)    # Dock自動非表示 (true:有効, false:無効)
DOCK_RECENTS=$(get_default_value com.apple.dock show-recents false) # 最近使用したアプリの表示 (true:表示, false:非表示)

# Finderの設定値を取得
FINDER_PATHBAR=$(get_default_value com.apple.finder ShowPathbar false)      # パスバー表示 (true:表示, false:非表示)
FINDER_STATUSBAR=$(get_default_value com.apple.finder ShowStatusBar false)  # ステータスバー表示 (true:表示, false:非表示)
FINDER_SHOW_HIDDEN=$(get_default_value com.apple.finder AppleShowAllFiles false) # 隠しファイル表示 (true:表示, false:非表示)

# ホットコーナーの設定値を取得
HOT_CORNER_TL=$(get_default_value com.apple.dock wvous-tl-corner 1)   # 左上のホットコーナー (1:何もしない, 2:Mission Control, 3:アプリケーションウィンドウ, 4:デスクトップ, 5:スクリーンセーバー開始, 6:スクリーンセーバー無効, 7:Dashboard, 10:ディスプレイをスリープさせる, 11:Launchpad, 12:通知センター)
HOT_CORNER_TR=$(get_default_value com.apple.dock wvous-tr-corner 1)   # 右上のホットコーナー
HOT_CORNER_BL=$(get_default_value com.apple.dock wvous-bl-corner 1)   # 左下のホットコーナー
HOT_CORNER_BR=$(get_default_value com.apple.dock wvous-br-corner 1)   # 右下のホットコーナー

# その他の設定値を取得
MENU_BAR_HIDDEN=$(get_default_value NSGlobalDomain _HIHideMenuBar false)    # メニューバー自動非表示 (true:有効, false:無効)
ACCENT_COLOR=$(get_default_value -g AppleAccentColor 0)                     # アクセントカラー (0:マルチカラー, 1:青, 2:紫, 3:ピンク, 4:赤, 5:オレンジ, 6:黄)

# ディスプレイ設定を取得（displayplacerが利用可能な場合）
DISPLAY_COMMAND=""
if command -v displayplacer >/dev/null 2>&1; then
    # displayplacerの出力から現在の設定を抽出（解像度、リフレッシュレート、配置など）
    DISPLAY_OUTPUT=$(displayplacer list 2>/dev/null | grep "^displayplacer")
    if [[ -n "$DISPLAY_OUTPUT" ]]; then
        DISPLAY_COMMAND=$(echo "$DISPLAY_OUTPUT" | sed 's/displayplacer //')
    fi
fi

# ================================================
# リストアスクリプトの生成
# ================================================

# トラックパッドの設定
TRACKPAD_COMMANDS=$(cat << EOF
defaults write -g com.apple.trackpad.scaling -float $TRACKPAD_SPEED
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int $FIRST_CLICK_THRESHOLD
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int $SECOND_CLICK_THRESHOLD
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool $(format_bool_value $TAP_TO_CLICK)
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool $(format_bool_value $DRAGGING)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool $(format_bool_value $THREE_FINGER_DRAG)
EOF
)

# システムサウンドの設定
SOUND_COMMANDS=$(cat << EOF
defaults write com.apple.systemsound com.apple.sound.beep.flash -bool $(format_bool_value $STARTUP_SOUND)
defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -bool $(format_bool_value $UI_SOUND)
defaults write -g com.apple.sound.beep.feedback -bool $(format_bool_value $VOLUME_FEEDBACK)
defaults write -g com.apple.sound.beep.sound -string "$ALERT_SOUND"
EOF
)

# Dockの設定
DOCK_COMMANDS=$(cat << EOF
defaults write com.apple.dock tilesize -int $DOCK_SIZE
defaults write com.apple.dock autohide -bool $(format_bool_value $DOCK_AUTOHIDE)
defaults write com.apple.dock show-recents -bool $(format_bool_value $DOCK_RECENTS)
EOF
)

# Finderの設定
FINDER_COMMANDS=$(cat << EOF
defaults write com.apple.finder ShowPathbar -bool $(format_bool_value $FINDER_PATHBAR)
defaults write com.apple.finder ShowStatusBar -bool $(format_bool_value $FINDER_STATUSBAR)
defaults write com.apple.finder AppleShowAllFiles -bool $(format_bool_value $FINDER_SHOW_HIDDEN)
EOF
)

# ホットコーナーの設定
HOT_CORNER_COMMANDS=$(cat << EOF
defaults write com.apple.dock wvous-tl-corner -int $HOT_CORNER_TL
defaults write com.apple.dock wvous-tr-corner -int $HOT_CORNER_TR
defaults write com.apple.dock wvous-bl-corner -int $HOT_CORNER_BL
defaults write com.apple.dock wvous-br-corner -int $HOT_CORNER_BR
EOF
)

# その他の設定
OTHER_COMMANDS=$(cat << EOF
defaults write NSGlobalDomain _HIHideMenuBar -bool $(format_bool_value $MENU_BAR_HIDDEN)
defaults write -g AppleAccentColor -int $ACCENT_COLOR
defaults write com.apple.screencapture location "\$HOME/Desktop"
EOF
)

# ヘッダーの作成
echo "#!/bin/bash" > "$OUTPUT_FILE"

# 設定の追加
add_setting "トラックパッド" "$TRACKPAD_COMMANDS"
add_setting "サウンド" "$SOUND_COMMANDS"
add_setting "Dock" "$DOCK_COMMANDS"
add_setting "Finder" "$FINDER_COMMANDS"
add_setting "ホットコーナー" "$HOT_CORNER_COMMANDS"
add_setting "その他" "$OTHER_COMMANDS"

# 設定の反映用コマンド
echo "# 設定の反映" >> "$OUTPUT_FILE"
echo "killall Dock" >> "$OUTPUT_FILE"
echo "killall Finder" >> "$OUTPUT_FILE"
echo "killall SystemUIServer" >> "$OUTPUT_FILE"

# 実行権限を付与
chmod +x "$OUTPUT_FILE"

echo "設定スクリプトを生成しました: $OUTPUT_FILE" 