#!/bin/bash
# トラックパッド
defaults write -g com.apple.trackpad.scaling -float 1.5
defaults write com.apple.AppleMultitouchTrackpad FirstClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad SecondClickThreshold -int 1
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool $(format_bool_value 1)
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool $(format_bool_value 0)
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool $(format_bool_value 0)

# サウンド
defaults write com.apple.systemsound com.apple.sound.beep.flash -bool $(format_bool_value 0)
defaults write com.apple.systemsound com.apple.sound.uiaudio.enabled -bool $(format_bool_value 0)
defaults write -g com.apple.sound.beep.feedback -bool $(format_bool_value 0)
defaults write -g com.apple.sound.beep.sound -string "/System/Library/Sounds/Boop.aiff"

# Dock
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool $(format_bool_value 0)
defaults write com.apple.dock show-recents -bool $(format_bool_value 0)

# Finder
defaults write com.apple.finder ShowPathbar -bool $(format_bool_value 0)
defaults write com.apple.finder ShowStatusBar -bool $(format_bool_value 0)
defaults write com.apple.finder AppleShowAllFiles -bool $(format_bool_value 0)

# その他
defaults write NSGlobalDomain _HIHideMenuBar -bool $(format_bool_value 0)
defaults write -g AppleAccentColor -int 2
defaults write com.apple.screencapture location "$HOME/Desktop"

# 設定の反映
killall Dock
killall Finder
killall SystemUIServer
