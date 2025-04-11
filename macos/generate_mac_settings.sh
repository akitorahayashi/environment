#!/bin/bash

# ================================================
# generate_mac_settings.sh
# 現在の macOS の設定を取得し、自動で setup_mac_settings.sh を生成
# ================================================
#
# 【使い方】
# 1. 実行権限を付与
#    chmod +x generate_mac_settings.sh
# 2. スクリプトを実行
#    ./generate_mac_settings.sh
# 3. setup_mac_settings.sh が作成される
# 4. setup_mac_settings.sh を適用するには:
#    source ./setup_mac_settings.sh
#
# ================================================

# 現在のスクリプトディレクトリを取得
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
ENVIRONMENT_DIR="$( cd "$SCRIPT_DIR/.." && pwd )"

OUTPUT_FILE="$ENVIRONMENT_DIR/setup_mac_settings.sh"
BACKUP_FILE="$ENVIRONMENT_DIR/setup_mac_settings.bak"

echo "現在の macOS の設定を取得し、$OUTPUT_FILE を生成します..."

# 既存の設定ファイルをバックアップ
if [ -f "$OUTPUT_FILE" ]; then
    mv "$OUTPUT_FILE" "$BACKUP_FILE"
    echo "既存の設定ファイルをバックアップしました: $BACKUP_FILE"
fi

# 設定スクリプトのヘッダーを作成
cat <<EOF > "$OUTPUT_FILE"
#!/bin/bash

echo "Mac のシステム設定を適用中..."
EOF

# 値を取得し、存在しない場合はデフォルト値にフォールバックする関数
get_default_value() {
    local value
    value=$(defaults read "$1" "$2" 2>/dev/null || echo "$3")
    [[ -z "$value" ]] && value="$3"
    echo "$value"
}

# トラックパッドの設定
TRACKPAD_SPEED=$(get_default_value -g com.apple.trackpad.scaling 1.5)
TAP_TO_CLICK=$(get_default_value com.apple.AppleMultitouchTrackpad Clicking 1)
DRAGGING=$(get_default_value com.apple.AppleMultitouchTrackpad Dragging 0)
THREE_FINGER_DRAG=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag 0)
FIRST_CLICK_THRESHOLD=$(get_default_value com.apple.AppleMultitouchTrackpad FirstClickThreshold 1)
SECOND_CLICK_THRESHOLD=$(get_default_value com.apple.AppleMultitouchTrackpad SecondClickThreshold 1)
ACTUATE_DETENTS=$(get_default_value com.apple.AppleMultitouchTrackpad ActuateDetents true)
FORCE_SUPPRESSED=$(get_default_value com.apple.AppleMultitouchTrackpad ForceSuppressed false)
THREE_FINGER_TAP=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture 0)
RIGHT_CLICK=$(get_default_value com.apple.AppleMultitouchTrackpad TrackpadRightClick true)
BT_RIGHT_CLICK=$(get_default_value com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick true)
BT_CLICKING=$(get_default_value com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking true)

# システムサウンドの設定
STARTUP_SOUND=$(get_default_value com.apple.systemsound "com.apple.sound.beep.flash" false)
UI_SOUND=$(get_default_value com.apple.systemsound "com.apple.sound.uiaudio.enabled" false)
VOLUME_FEEDBACK=$(get_default_value -g "com.apple.sound.beep.feedback" false)
ALERT_SOUND=$(get_default_value -g "com.apple.sound.beep.sound" "/System/Library/Sounds/Boop.aiff")

# システムサウンドの設定を追加
echo "# サウンドエフェクトの設定" >> "$OUTPUT_FILE"
echo "defaults write com.apple.systemsound com.apple.sound.beep.flash -bool $STARTUP_SOUND" >> "$OUTPUT_FILE"
echo "defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -bool $UI_SOUND" >> "$OUTPUT_FILE"
echo "defaults write -g com.apple.sound.beep.feedback -bool $VOLUME_FEEDBACK" >> "$OUTPUT_FILE"
echo "defaults write -g com.apple.sound.beep.sound -string \"$ALERT_SOUND\"" >> "$OUTPUT_FILE"

# アクセントカラーの設定
ACCENT_COLOR=$(get_default_value -g AppleAccentColor 0)

# トラックパッド設定を出力
echo "" >> "$OUTPUT_FILE"
echo "# トラックパッド設定" >> "$OUTPUT_FILE"
echo "echo \"トラックパッドの設定を適用中...\"" >> "$OUTPUT_FILE"
echo "# 軌跡の速さ (0.0 - 3.0 の範囲で設定)" >> "$OUTPUT_FILE"
echo "defaults write -g com.apple.trackpad.scaling -float $TRACKPAD_SPEED" >> "$OUTPUT_FILE"
echo "# クリックの強さ (0 - 2 の範囲で設定)" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int $FIRST_CLICK_THRESHOLD" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int $SECOND_CLICK_THRESHOLD" >> "$OUTPUT_FILE"
echo "# 強めのクリックと触覚フィードバック" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -bool $ACTUATE_DETENTS" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool $FORCE_SUPPRESSED" >> "$OUTPUT_FILE"
echo "# 調べる＆データ検出 (1本指で強めのクリック)" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int $THREE_FINGER_TAP" >> "$OUTPUT_FILE"
echo "# 副ボタンのクリック (2本指でクリック)" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool $RIGHT_CLICK" >> "$OUTPUT_FILE"
echo "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool $BT_RIGHT_CLICK" >> "$OUTPUT_FILE"
echo "# タップでクリック" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad Clicking -bool $TAP_TO_CLICK" >> "$OUTPUT_FILE"
echo "defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool $BT_CLICKING" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad Dragging -bool $DRAGGING" >> "$OUTPUT_FILE"
echo "defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool $THREE_FINGER_DRAG" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "# マウス設定" >> "$OUTPUT_FILE"

# マウスの速度
MOUSE_SPEED=$(get_default_value -g com.apple.mouse.scaling 1.5)
[[ -n "$MOUSE_SPEED" ]] && echo "defaults write -g com.apple.mouse.scaling -float $MOUSE_SPEED" >> "$OUTPUT_FILE"

# キーボードのキーリピート速度
INITIAL_KEY_REPEAT=$(get_default_value -g InitialKeyRepeat 25)
KEY_REPEAT=$(get_default_value -g KeyRepeat 6)
[[ -n "$INITIAL_KEY_REPEAT" ]] && echo "defaults write -g InitialKeyRepeat -int $INITIAL_KEY_REPEAT" >> "$OUTPUT_FILE"
[[ -n "$KEY_REPEAT" ]] && echo "defaults write -g KeyRepeat -int $KEY_REPEAT" >> "$OUTPUT_FILE"

# Dock の設定
DOCK_SIZE=$(get_default_value com.apple.dock tilesize 50)
DOCK_AUTOHIDE=$(get_default_value com.apple.dock autohide false)
DOCK_RECENTS=$(get_default_value com.apple.dock show-recents false)
echo "defaults write com.apple.dock tilesize -int $DOCK_SIZE" >> "$OUTPUT_FILE"
[[ -n "$DOCK_AUTOHIDE" ]] && echo "defaults write com.apple.dock autohide -bool $DOCK_AUTOHIDE" >> "$OUTPUT_FILE"
[[ -n "$DOCK_RECENTS" ]] && echo "defaults write com.apple.dock show-recents -bool $DOCK_RECENTS" >> "$OUTPUT_FILE"

# ホットコーナーの設定
for CORNER in tl tr bl br; do
    CORNER_VALUE=$(defaults read com.apple.dock "wvous-${CORNER}-corner" 2>/dev/null || echo 0)
    MODIFIER_VALUE=$(defaults read com.apple.dock "wvous-${CORNER}-modifier" 2>/dev/null || echo 0)
    echo "defaults write com.apple.dock wvous-${CORNER}-corner -int $CORNER_VALUE" >> "$OUTPUT_FILE"
    echo "defaults write com.apple.dock wvous-${CORNER}-modifier -int $MODIFIER_VALUE" >> "$OUTPUT_FILE"
done
echo "killall Dock" >> "$OUTPUT_FILE"

# Finder の設定
FINDER_PATHBAR=$(get_default_value com.apple.finder ShowPathbar false)
FINDER_STATUSBAR=$(get_default_value com.apple.finder ShowStatusBar false)
FINDER_SHOW_HIDDEN=$(get_default_value com.apple.finder AppleShowAllFiles false)
[[ -n "$FINDER_PATHBAR" ]] && echo "defaults write com.apple.finder ShowPathbar -bool $FINDER_PATHBAR" >> "$OUTPUT_FILE"
[[ -n "$FINDER_STATUSBAR" ]] && echo "defaults write com.apple.finder ShowStatusBar -bool $FINDER_STATUSBAR" >> "$OUTPUT_FILE"
[[ -n "$FINDER_SHOW_HIDDEN" ]] && echo "defaults write com.apple.finder AppleShowAllFiles -bool $FINDER_SHOW_HIDDEN" >> "$OUTPUT_FILE"
echo "killall Finder" >> "$OUTPUT_FILE"

# メニューバーの設定
MENU_BAR_HIDDEN=$(get_default_value NSGlobalDomain _HIHideMenuBar false)
[[ -n "$MENU_BAR_HIDDEN" ]] && echo "defaults write NSGlobalDomain _HIHideMenuBar -bool $MENU_BAR_HIDDEN" >> "$OUTPUT_FILE"

# スクリーンショットの保存場所
SCREENSHOT_PATH=$(defaults read com.apple.screencapture location 2>/dev/null || echo "$HOME/Desktop")
[[ -n "$SCREENSHOT_PATH" ]] && echo "mkdir -p \"$SCREENSHOT_PATH\"" >> "$OUTPUT_FILE"
[[ -n "$SCREENSHOT_PATH" ]] && echo "defaults write com.apple.screencapture location \"$SCREENSHOT_PATH\"" >> "$OUTPUT_FILE"
echo "killall SystemUIServer" >> "$OUTPUT_FILE"

# スクリプトの最後にメッセージを追加
echo 'echo "Mac のシステム設定が適用されました ✅"' >> "$OUTPUT_FILE"

# 実行権限を付与
chmod +x "$OUTPUT_FILE"

echo "設定スクリプトを生成しました: $OUTPUT_FILE"
