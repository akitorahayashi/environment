#!/bin/bash
set -euo pipefail

# システム
defaults write NSGlobalDomain AppleHighlightColor -string "0.709800 0.835300 1.000000"
defaults write NSGlobalDomain AppleShowScrollBars -string "Automatic"
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool false
defaults write com.apple.LaunchServices LSQuarantine -bool false
defaults write com.apple.CrashReporter DialogType -string "none"

# UI/UX
defaults write NSGlobalDomain _HIHideMenuBar -bool false
defaults write com.apple.universalaccess reduceTransparency -bool false
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool true
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool true
defaults write NSGlobalDomain WebKitDeveloperExtras -bool true

# Dock
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock autohide-time-modifier -float 0.5
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock mineffect -string "genie"
defaults write com.apple.dock minimize-to-application -bool false
defaults write com.apple.dock static-only -int 0
defaults write com.apple.dock scroll-to-open -int 0
defaults write com.apple.dock launchanim -bool false
defaults write com.apple.dock showhidden -bool false

# Finder
defaults write com.apple.finder ShowPathbar -bool false
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder AppleShowAllFiles -bool false
defaults write NSGlobalDomain AppleShowAllExtensions -bool false
defaults write com.apple.finder _FXShowPosixPathInTitle -bool false
defaults write com.apple.finder FXPreferredViewStyle -string "icnv"
defaults write com.apple.finder _FXSortFoldersFirst -bool false
defaults write com.apple.finder FXDefaultSearchScope -string "SCev"
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool true
defaults write com.apple.finder WarnOnEmptyTrash -bool true
defaults write com.apple.finder FXRemoveOldTrashItems -bool false
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool false
defaults write com.apple.finder QuitMenuItem -bool false
defaults write com.apple.finder DisableAllAnimations -bool false
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# デスクトップ
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool true
defaults write com.apple.WindowManager EnableStandardClickToShowDesktop -bool false

# ミッションコントロール
defaults write com.apple.dock expose-animation-duration -float 0.2
defaults write com.apple.dock mru-spaces -bool true
defaults write com.apple.dock expose-group-by-app -bool true
defaults write com.apple.dock workspaces-auto-swoosh -bool false
defaults write com.apple.spaces spans-displays -bool false
defaults write com.apple.dashboard mcx-disabled -bool false

# ホットコーナー
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-br-corner -int 10

# キーボード
defaults write NSGlobalDomain KeyRepeat -int 6
defaults write NSGlobalDomain InitialKeyRepeat -int 25
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool true
defaults write NSGlobalDomain AppleKeyboardUIMode -int 1
defaults write -g com.apple.keyboard.fnState -bool false
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool true

# マウス
defaults write .GlobalPreferences com.apple.mouse.scaling -float 1.5
defaults write com.apple.Terminal FocusFollowsMouse -bool true

# トラックパッド
defaults write -g com.apple.trackpad.scaling -float 1.5
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool true
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool true

# サウンド
defaults write com.apple.systemsound "com.apple.sound.uiaudio.enabled" -int 0
defaults write -g "com.apple.sound.beep.feedback" -int 0
defaults write -g "com.apple.sound.beep.sound" -string "/System/Library/Sounds/Boop.aiff"
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

# スクリーンショット
defaults write com.apple.screencapture location -string "$HOME/Desktop"
defaults write com.apple.screencapture disable-shadow -bool false
defaults write com.apple.screencapture include-date -bool false
defaults write com.apple.screencapture show-thumbnail -bool true
defaults write com.apple.screencapture type -string "png"

# ディスプレイ
displayplacer "id:37D8832A-2D66-02CA-B9F7-8F30A301B230 res:1710x1112 hz:60 color_depth:8 enabled:true scaling:on origin:(0,0) degree:0"

