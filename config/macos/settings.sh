#!/bin/bash
# トラックパッド
defaults write -g com.apple.trackpad.scaling -float 1.5
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool false

# サウンド
defaults write com.apple.systemsound com.apple.sound.beep.flash -bool false
defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -bool false
defaults write -g com.apple.sound.beep.feedback -bool false
defaults write -g com.apple.sound.beep.sound -string "/System/Library/Sounds/Boop.aiff"

# Dock
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock show-recents -bool false

# Finder
defaults write com.apple.finder ShowPathbar -bool false
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder AppleShowAllFiles -bool false

# ホットコーナー
defaults write com.apple.dock wvous-tl-corner -int 1
defaults write com.apple.dock wvous-tr-corner -int 1
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-br-corner -int 10

# その他
defaults write NSGlobalDomain _HIHideMenuBar -bool false
defaults write -g AppleAccentColor -int 2
defaults write com.apple.screencapture location "$HOME/Desktop"

# 設定の反映
killall Dock
killall Finder
killall SystemUIServer 