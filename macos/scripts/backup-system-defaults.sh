#!/bin/bash
set -euo pipefail

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

OUTPUT_FILE="$SCRIPT_DIR/../config/system-defaults/system-defaults.sh"

OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

echo "現在の macOS の system defaults を取得し、$OUTPUT_FILE を生成します..."

# 既存の system defaults ファイルを削除
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "既存の system defaults ファイルを削除しました: $OUTPUT_FILE"
fi

# 設定スクリプトのヘッダーを作成
cat <<EOF > "$OUTPUT_FILE"
#!/bin/bash
set -euo pipefail

EOF

# ================================================
# ユーティリティ関数の定義
# ================================================

# 値を取得し、存在しない場合はデフォルト値にフォールバックする関数
get_default_value() {
    local value
    value=$(defaults read "$1" "$2" 2>/dev/null) || value="$3"
    echo "$value"
}

# bool値を適切な形式に変換する関数
format_bool_value() {
    local value
    value="$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)"
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

# --- システム ---
CRASH_REPORTER_DIALOG=$(get_default_value "com.apple.CrashReporter" "DialogType" "none")
ACCENT_COLOR=$(get_default_value "NSGlobalDomain" "AppleHighlightColor" "0.764700 0.976500 0.568600")
SCROLL_BARS=$(get_default_value "NSGlobalDomain" "AppleShowScrollBars" "Automatic")
SAVE_PANEL_EXPANDED=$(get_default_value "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode" "false")
SAVE_PANEL_EXPANDED2=$(get_default_value "NSGlobalDomain" "NSNavPanelExpandedStateForSaveMode2" "false")
PRINT_PANEL_EXPANDED=$(get_default_value "NSGlobalDomain" "PMPrintingExpandedStateForPrint" "false")
PRINT_PANEL_EXPANDED2=$(get_default_value "NSGlobalDomain" "PMPrintingExpandedStateForPrint2" "false")
SAVE_TO_ICLOUD=$(get_default_value "NSGlobalDomain" "NSDocumentSaveNewDocumentsToCloud" "true")
QUIT_ALWAYS_KEEPS_WINDOWS=$(get_default_value "com.apple.systempreferences" "NSQuitAlwaysKeepsWindows" "false")
DISABLE_AUTO_TERMINATION=$(get_default_value "NSGlobalDomain" "NSDisableAutomaticTermination" "false")
LSQUARANTINE=$(get_default_value "com.apple.LaunchServices" "LSQuarantine" "true")

# --- UI/UX ---
HIDE_MENU_BAR=$(get_default_value "NSGlobalDomain" "_HIHideMenuBar" "false")
SIDEBAR_ICON_SIZE=$(get_default_value "NSGlobalDomain" "NSTableViewDefaultSizeMode" "2")
WINDOW_RESIZE_TIME=$(get_default_value "NSGlobalDomain" "NSWindowResizeTime" "0.001")
AUTO_CAPITALIZATION=$(get_default_value "NSGlobalDomain" "NSAutomaticCapitalizationEnabled" "true")
SMART_DASHES=$(get_default_value "NSGlobalDomain" "NSAutomaticDashSubstitutionEnabled" "true")
AUTO_PERIOD_SUBSTITUTION=$(get_default_value "NSGlobalDomain" "NSAutomaticPeriodSubstitutionEnabled" "true")
SMART_QUOTES=$(get_default_value "NSGlobalDomain" "NSAutomaticQuoteSubstitutionEnabled" "true")
AUTO_SPELLING_CORRECTION=$(get_default_value "NSGlobalDomain" "NSAutomaticSpellingCorrectionEnabled" "true")
WEBKIT_DEVELOPER_EXTRAS=$(get_default_value "NSGlobalDomain" "WebKitDeveloperExtras" "false")
SWIPE_NAVIGATE_WITH_SCROLLS=$(get_default_value "NSGlobalDomain" "AppleEnableSwipeNavigateWithScrolls" "false")

# --- Dock ---
DOCK_SIZE=$(get_default_value "com.apple.dock" "tilesize" "50")
DOCK_AUTOHIDE=$(get_default_value "com.apple.dock" "autohide" "false")
DOCK_AUTOHIDE_TIME=$(get_default_value "com.apple.dock" "autohide-time-modifier" "0.5")
DOCK_AUTOHIDE_DELAY=$(get_default_value "com.apple.dock" "autohide-delay" "0")
DOCK_SHOW_RECENTS=$(get_default_value "com.apple.dock" "show-recents" "true")
DOCK_MIN_EFFECT=$(get_default_value "com.apple.dock" "mineffect" "genie")
DOCK_MIN_TO_APP=$(get_default_value "com.apple.dock" "minimize-to-application" "false")
DOCK_STATIC_ONLY=$(get_default_value "com.apple.dock" "static-only" "false")
DOCK_SCROLL_TO_OPEN=$(get_default_value "com.apple.dock" "scroll-to-open" "false")
DOCK_LAUNCH_ANIM=$(get_default_value "com.apple.dock" "launchanim" "true")
DOCK_SHOW_HIDDEN=$(get_default_value "com.apple.dock" "showhidden" "false")
DOCK_NO_BOUNCING=$(get_default_value "com.apple.dock" "no-bouncing" "false")

# --- Finder ---
FINDER_SHOW_PATHBAR=$(get_default_value "com.apple.finder" "ShowPathbar" "false")
FINDER_SHOW_STATUSBAR=$(get_default_value "com.apple.finder" "ShowStatusBar" "false")
FINDER_SHOW_HIDDEN_FILES=$(get_default_value "com.apple.finder" "AppleShowAllFiles" "false")
FINDER_SHOW_EXTENSIONS=$(get_default_value "NSGlobalDomain" "AppleShowAllExtensions" "false")
FINDER_SHOW_POSIX_PATH_IN_TITLE=$(get_default_value "com.apple.finder" "_FXShowPosixPathInTitle" "false")
FINDER_PREFERRED_VIEW_STYLE=$(get_default_value "com.apple.finder" "FXPreferredViewStyle" "Nlsv")
FINDER_SORT_FOLDERS_FIRST=$(get_default_value "com.apple.finder" "_FXSortFoldersFirst" "false")
FINDER_DEFAULT_SEARCH_SCOPE=$(get_default_value "com.apple.finder" "FXDefaultSearchScope" "SCev")
FINDER_WARN_ON_EXT_CHANGE=$(get_default_value "com.apple.finder" "FXEnableExtensionChangeWarning" "true")
FINDER_WARN_ON_EMPTY_TRASH=$(get_default_value "com.apple.finder" "WarnOnEmptyTrash" "true")
FINDER_REMOVE_OLD_TRASH_ITEMS=$(get_default_value "com.apple.finder" "FXRemoveOldTrashItems" "false")
FINDER_DONT_WRITE_NETWORK_STORES=$(get_default_value "com.apple.desktopservices" "DSDontWriteNetworkStores" "false")
FINDER_QUIT_MENU=$(get_default_value "com.apple.finder" "QuitMenuItem" "false")
FINDER_DISABLE_ALL_ANIMATIONS=$(get_default_value "com.apple.finder" "DisableAllAnimations" "false")
FINDER_SPRINGING_ENABLED=$(get_default_value "NSGlobalDomain" "com.apple.springing.enabled" "false")

# --- デスクトップ ---
SHOW_EXTERNAL_HD_ON_DESKTOP=$(get_default_value "com.apple.finder" "ShowExternalHardDrivesOnDesktop" "true")
CLICK_TO_SHOW_DESKTOP=$(get_default_value "com.apple.WindowManager" "EnableStandardClickToShowDesktop" "false")
STAGE_MANAGER_ENABLED=$(get_default_value "com.apple.WindowManager" "GloballyEnabled" "false")

# --- ミッションコントロール ---
MC_ANIMATION_DURATION=$(get_default_value "com.apple.dock" "expose-animation-duration" "0.2")
MC_AUTO_REARRANGE=$(get_default_value "com.apple.dock" "mru-spaces" "true")
MC_GROUP_BY_APP=$(get_default_value "com.apple.dock" "expose-group-by-app" "true")
MC_AUTO_SWOOSH=$(get_default_value "com.apple.dock" "workspaces-auto-swoosh" "false")
MC_SPANS_DISPLAYS=$(get_default_value "com.apple.spaces" "spans-displays" "false")

# --- ホットコーナー ---
HOT_CORNER_TL=$(get_default_value "com.apple.dock" "wvous-tl-corner" "1")
HOT_CORNER_TR=$(get_default_value "com.apple.dock" "wvous-tr-corner" "1")
HOT_CORNER_BL=$(get_default_value "com.apple.dock" "wvous-bl-corner" "1")
HOT_CORNER_BR=$(get_default_value "com.apple.dock" "wvous-br-corner" "1")

# --- キーボード ---
KEY_REPEAT_RATE=$(get_default_value "NSGlobalDomain" "KeyRepeat" "2")
KEY_REPEAT_DELAY=$(get_default_value "NSGlobalDomain" "InitialKeyRepeat" "15")
PRESS_AND_HOLD=$(get_default_value "NSGlobalDomain" "ApplePressAndHoldEnabled" "true")
KEYBOARD_UI_MODE=$(get_default_value "NSGlobalDomain" "AppleKeyboardUIMode" "1")
FN_STATE=$(get_default_value -g "com.apple.keyboard.fnState" "false")
NATURAL_SCROLLING=$(get_default_value "NSGlobalDomain" "com.apple.swipescrolldirection" "true")

# --- マウス ---
MOUSE_SCALING=$(get_default_value ".GlobalPreferences" "com.apple.mouse.scaling" "1.0")
FOCUS_FOLLOWS_MOUSE=$(get_default_value "com.apple.Terminal" "FocusFollowsMouse" "false")

# --- トラックパッド ---
TRACKPAD_SCALING=$(get_default_value -g "com.apple.trackpad.scaling" "1.5")
TRACKPAD_CLICKING=$(get_default_value "com.apple.AppleMultitouchTrackpad" "Clicking" "1")
TRACKPAD_DRAGGING=$(get_default_value "com.apple.AppleMultitouchTrackpad" "Dragging" "0")
TRACKPAD_3FINGER_DRAG=$(get_default_value "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerDrag" "0")
TRACKPAD_FIRST_CLICK_THRESHOLD=$(get_default_value "com.apple.AppleMultitouchTrackpad" "FirstClickThreshold" "1")
TRACKPAD_FORCE_SUPPRESSED=$(get_default_value "com.apple.AppleMultitouchTrackpad" "ForceSuppressed" "false")
TRACKPAD_3FINGER_TAP_GESTURE=$(get_default_value "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerTapGesture" "2")
TRACKPAD_RIGHT_CLICK=$(get_default_value "com.apple.AppleMultitouchTrackpad" "TrackpadRightClick" "true")

# --- サウンド ---
UI_SOUND=$(get_default_value "com.apple.systemsound" "com.apple.sound.uiaudio.enabled" "1")
VOLUME_FEEDBACK=$(get_default_value -g "com.apple.sound.beep.feedback" "1")
ALERT_SOUND_PATH=$(get_default_value -g "com.apple.sound.beep.sound" "")
BLUETOOTH_AUDIO_BITPOOL=$(get_default_value "com.apple.BluetoothAudioAgent" "Apple Bitpool Min (editable)" "40")

# --- スクリーンショット ---
SCREENSHOT_LOCATION=$(get_default_value "com.apple.screencapture" "location" "$HOME/Desktop")
# SCREENSHOT_LOCATIONのパスを$HOMEで置換
SCREENSHOT_LOCATION_ESCAPED="${SCREENSHOT_LOCATION/#$HOME/\$HOME}"
SCREENSHOT_DISABLE_SHADOW=$(get_default_value "com.apple.screencapture" "disable-shadow" "false")
SCREENSHOT_INCLUDE_DATE=$(get_default_value "com.apple.screencapture" "include-date" "false")
SCREENSHOT_SHOW_THUMBNAIL=$(get_default_value "com.apple.screencapture" "show-thumbnail" "true")
SCREENSHOT_TYPE=$(get_default_value "com.apple.screencapture" "type" "png")

# ================================================
# リストアスクリプトの生成
# ================================================

# --- システム ---
SYSTEM_COMMANDS=$(cat << EOF
defaults write NSGlobalDomain AppleHighlightColor -string "$ACCENT_COLOR"
defaults write NSGlobalDomain AppleShowScrollBars -string "$SCROLL_BARS"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool $(format_bool_value $SAVE_PANEL_EXPANDED)
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool $(format_bool_value $SAVE_PANEL_EXPANDED2)
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool $(format_bool_value $PRINT_PANEL_EXPANDED)
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool $(format_bool_value $PRINT_PANEL_EXPANDED2)
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool $(format_bool_value $SAVE_TO_ICLOUD)
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool $(format_bool_value $QUIT_ALWAYS_KEEPS_WINDOWS)
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool $(format_bool_value $DISABLE_AUTO_TERMINATION)
defaults write com.apple.LaunchServices LSQuarantine -bool $(format_bool_value $LSQUARANTINE)
defaults write com.apple.CrashReporter DialogType -string "$CRASH_REPORTER_DIALOG"
EOF
)

# --- UI/UX ---
UIUX_COMMANDS=$(cat << EOF
defaults write NSGlobalDomain _HIHideMenuBar -bool $(format_bool_value $HIDE_MENU_BAR)
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int $SIDEBAR_ICON_SIZE
defaults write NSGlobalDomain NSWindowResizeTime -float $WINDOW_RESIZE_TIME
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool $(format_bool_value $AUTO_CAPITALIZATION)
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool $(format_bool_value $SMART_DASHES)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool $(format_bool_value $AUTO_PERIOD_SUBSTITUTION)
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool $(format_bool_value $SMART_QUOTES)
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool $(format_bool_value $AUTO_SPELLING_CORRECTION)
defaults write NSGlobalDomain WebKitDeveloperExtras -bool $(format_bool_value $WEBKIT_DEVELOPER_EXTRAS)
defaults write NSGlobalDomain AppleEnableSwipeNavigateWithScrolls -bool $(format_bool_value $SWIPE_NAVIGATE_WITH_SCROLLS)
EOF
)

# ================================================
# 設定の書き出し
# ================================================

# --- Dock ---
DOCK_COMMANDS=$(cat << EOF
defaults write com.apple.dock tilesize -int $DOCK_SIZE
defaults write com.apple.dock autohide -bool $(format_bool_value $DOCK_AUTOHIDE)
defaults write com.apple.dock autohide-time-modifier -float $DOCK_AUTOHIDE_TIME
defaults write com.apple.dock autohide-delay -float $DOCK_AUTOHIDE_DELAY
defaults write com.apple.dock show-recents -bool $(format_bool_value $DOCK_SHOW_RECENTS)
defaults write com.apple.dock mineffect -string "$DOCK_MIN_EFFECT"
defaults write com.apple.dock minimize-to-application -bool $(format_bool_value $DOCK_MIN_TO_APP)
defaults write com.apple.dock static-only -bool $(format_bool_value $DOCK_STATIC_ONLY)
defaults write com.apple.dock scroll-to-open -bool $(format_bool_value $DOCK_SCROLL_TO_OPEN)
defaults write com.apple.dock launchanim -bool $(format_bool_value $DOCK_LAUNCH_ANIM)
defaults write com.apple.dock showhidden -bool $(format_bool_value $DOCK_SHOW_HIDDEN)
defaults write com.apple.dock no-bouncing -bool $(format_bool_value $DOCK_NO_BOUNCING)
EOF
)

# --- Finder ---
FINDER_COMMANDS=$(cat << EOF
defaults write com.apple.finder ShowPathbar -bool $(format_bool_value $FINDER_SHOW_PATHBAR)
defaults write com.apple.finder ShowStatusBar -bool $(format_bool_value $FINDER_SHOW_STATUSBAR)
defaults write com.apple.finder AppleShowAllFiles -bool $(format_bool_value $FINDER_SHOW_HIDDEN_FILES)
defaults write NSGlobalDomain AppleShowAllExtensions -bool $(format_bool_value $FINDER_SHOW_EXTENSIONS)
defaults write com.apple.finder _FXShowPosixPathInTitle -bool $(format_bool_value $FINDER_SHOW_POSIX_PATH_IN_TITLE)
defaults write com.apple.finder FXPreferredViewStyle -string "$FINDER_PREFERRED_VIEW_STYLE"
defaults write com.apple.finder _FXSortFoldersFirst -bool $(format_bool_value $FINDER_SORT_FOLDERS_FIRST)
defaults write com.apple.finder FXDefaultSearchScope -string "$FINDER_DEFAULT_SEARCH_SCOPE"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool $(format_bool_value $FINDER_WARN_ON_EXT_CHANGE)
defaults write com.apple.finder WarnOnEmptyTrash -bool $(format_bool_value $FINDER_WARN_ON_EMPTY_TRASH)
defaults write com.apple.finder FXRemoveOldTrashItems -bool $(format_bool_value $FINDER_REMOVE_OLD_TRASH_ITEMS)
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool $(format_bool_value $FINDER_DONT_WRITE_NETWORK_STORES)
defaults write com.apple.finder QuitMenuItem -bool $(format_bool_value $FINDER_QUIT_MENU)
defaults write com.apple.finder DisableAllAnimations -bool $(format_bool_value $FINDER_DISABLE_ALL_ANIMATIONS)
defaults write NSGlobalDomain com.apple.springing.enabled -bool $(format_bool_value $FINDER_SPRINGING_ENABLED)
EOF
)

add_setting "システム" "$SYSTEM_COMMANDS"
add_setting "UI/UX" "$UIUX_COMMANDS"
add_setting "Dock" "$DOCK_COMMANDS"
add_setting "Finder" "$FINDER_COMMANDS"

# --- デスクトップ ---
DESKTOP_COMMANDS=$(cat << EOF
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool $(format_bool_value $SHOW_EXTERNAL_HD_ON_DESKTOP)
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool $(format_bool_value $CLICK_TO_SHOW_DESKTOP)
defaults write com.apple.WindowManager GloballyEnabled -bool $(format_bool_value $STAGE_MANAGER_ENABLED)
EOF
)

# --- ミッションコントロール ---
MISSION_CONTROL_COMMANDS=$(cat << EOF
defaults write com.apple.dock expose-animation-duration -float $MC_ANIMATION_DURATION
defaults write com.apple.dock mru-spaces -bool $(format_bool_value $MC_AUTO_REARRANGE)
defaults write com.apple.dock expose-group-by-app -bool $(format_bool_value $MC_GROUP_BY_APP)
defaults write com.apple.dock workspaces-auto-swoosh -bool $(format_bool_value $MC_AUTO_SWOOSH)
defaults write com.apple.spaces spans-displays -bool $(format_bool_value $MC_SPANS_DISPLAYS)
EOF
)

# --- ホットコーナー ---
HOT_CORNER_COMMANDS=$(cat << EOF
defaults write com.apple.dock wvous-tl-corner -int $HOT_CORNER_TL
defaults write com.apple.dock wvous-tr-corner -int $HOT_CORNER_TR
defaults write com.apple.dock wvous-bl-corner -int $HOT_CORNER_BL
defaults write com.apple.dock wvous-br-corner -int $HOT_CORNER_BR
EOF
)

add_setting "デスクトップ" "$DESKTOP_COMMANDS"
add_setting "ミッションコントロール" "$MISSION_CONTROL_COMMANDS"
add_setting "ホットコーナー" "$HOT_CORNER_COMMANDS"

# --- キーボード ---
KEYBOARD_COMMANDS=$(cat << EOF
defaults write NSGlobalDomain KeyRepeat -int $KEY_REPEAT_RATE
defaults write NSGlobalDomain InitialKeyRepeat -int $KEY_REPEAT_DELAY
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool $(format_bool_value $PRESS_AND_HOLD)
defaults write NSGlobalDomain AppleKeyboardUIMode -int $KEYBOARD_UI_MODE
defaults write -g com.apple.keyboard.fnState -bool $(format_bool_value $FN_STATE)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool $(format_bool_value $NATURAL_SCROLLING)
EOF
)

# --- マウス ---
MOUSE_COMMANDS=$(cat << EOF
defaults write .GlobalPreferences com.apple.mouse.scaling -float $MOUSE_SCALING
defaults write com.apple.Terminal FocusFollowsMouse -bool $(format_bool_value $FOCUS_FOLLOWS_MOUSE)
EOF
)

# --- トラックパッド ---
TRACKPAD_COMMANDS=$(cat << EOF
defaults write -g com.apple.trackpad.scaling -float $TRACKPAD_SCALING
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool $(format_bool_value $TRACKPAD_CLICKING)
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool $(format_bool_value $TRACKPAD_DRAGGING)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool $(format_bool_value $TRACKPAD_3FINGER_DRAG)
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int $TRACKPAD_FIRST_CLICK_THRESHOLD
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool $(format_bool_value $TRACKPAD_FORCE_SUPPRESSED)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int $TRACKPAD_3FINGER_TAP_GESTURE
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool $(format_bool_value $TRACKPAD_RIGHT_CLICK)
EOF
)

# --- サウンド ---
SOUND_COMMANDS=$(cat << EOF
defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int $UI_SOUND
defaults write -g "com.apple.sound.beep.feedback" -int $VOLUME_FEEDBACK
defaults write -g "com.apple.sound.beep.sound" -string "$ALERT_SOUND_PATH"
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int $BLUETOOTH_AUDIO_BITPOOL
EOF
)

# --- スクリーンショット ---
SCREENSHOT_COMMANDS=$(cat << EOF
defaults write com.apple.screencapture location -string "$SCREENSHOT_LOCATION_ESCAPED"
defaults write com.apple.screencapture disable-shadow -bool $(format_bool_value $SCREENSHOT_DISABLE_SHADOW)
defaults write com.apple.screencapture include-date -bool $(format_bool_value $SCREENSHOT_INCLUDE_DATE)
defaults write com.apple.screencapture show-thumbnail -bool $(format_bool_value $SCREENSHOT_SHOW_THUMBNAIL)
defaults write com.apple.screencapture type -string "$SCREENSHOT_TYPE"
EOF
)

add_setting "キーボード" "$KEYBOARD_COMMANDS"
add_setting "マウス" "$MOUSE_COMMANDS"
add_setting "トラックパッド" "$TRACKPAD_COMMANDS"
add_setting "サウンド" "$SOUND_COMMANDS"
add_setting "スクリーンショット" "$SCREENSHOT_COMMANDS"

# 実行権限を付与
chmod +x "$OUTPUT_FILE"

echo "system defaults スクリプトを生成しました: $OUTPUT_FILE"