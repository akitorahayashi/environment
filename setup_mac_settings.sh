#!/bin/bash

echo "Mac のシステム設定を適用中..."
# サウンドエフェクトの設定
defaults write com.apple.systemsound com.apple.sound.beep.flash -bool false
defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -bool false
defaults write -g com.apple.sound.beep.feedback -bool false
defaults write -g com.apple.sound.beep.sound -string "/System/Library/Sounds/Boop.aiff"

# トラックパッド設定
echo "トラックパッドの設定を適用中..."
# 軌跡の速さ (0.0 - 3.0 の範囲で設定)
defaults write -g com.apple.trackpad.scaling -float 1.5
# クリックの強さ (0 - 2 の範囲で設定)
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
# 強めのクリックと触覚フィードバック
defaults write com.apple.AppleMultitouchTrackpad ActuateDetents -bool 1
defaults write com.apple.AppleMultitouchTrackpad ForceSuppressed -bool 0
# 調べる＆データ検出 (1本指で強めのクリック)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerTapGesture -int 0
# 副ボタンのクリック (2本指でクリック)
defaults write com.apple.AppleMultitouchTrackpad TrackpadRightClick -bool 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadRightClick -bool 1
# タップでクリック
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool 1
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool 1
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool 0
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool 0

# マウス設定
defaults write -g com.apple.mouse.scaling -float 1.5
defaults write -g InitialKeyRepeat -int 25
defaults write -g KeyRepeat -int 6
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool 0
defaults write com.apple.dock show-recents -bool 0
defaults write com.apple.dock wvous-tl-corner -int 11
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 10
defaults write com.apple.dock wvous-br-modifier -int 0
killall Dock
defaults write com.apple.finder ShowPathbar -bool 0
defaults write com.apple.finder ShowStatusBar -bool 0
defaults write com.apple.finder AppleShowAllFiles -bool 0
killall Finder
defaults write NSGlobalDomain _HIHideMenuBar -bool 0
mkdir -p "/Users/akitora.hayashi/Desktop"
defaults write com.apple.screencapture location "/Users/akitora.hayashi/Desktop"
killall SystemUIServer
echo "Mac のシステム設定が適用されました ✅"
