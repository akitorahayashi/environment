#!/bin/bash

echo "Mac のシステム設定を適用中..."
defaults write -g com.apple.trackpad.scaling -float 1.5
defaults write -g com.apple.mouse.scaling -float 1.5
defaults write -g InitialKeyRepeat -int 25
defaults write -g KeyRepeat -int 6
defaults write com.apple.dock tilesize -int 50
defaults write com.apple.dock autohide -bool false
defaults write com.apple.dock show-recents -bool false
defaults write com.apple.dock wvous-tl-corner -int 11
defaults write com.apple.dock wvous-tl-modifier -int 0
defaults write com.apple.dock wvous-tr-corner -int 2
defaults write com.apple.dock wvous-tr-modifier -int 0
defaults write com.apple.dock wvous-bl-corner -int 10
defaults write com.apple.dock wvous-bl-modifier -int 0
defaults write com.apple.dock wvous-br-corner -int 10
defaults write com.apple.dock wvous-br-modifier -int 0
killall Dock
defaults write com.apple.finder ShowPathbar -bool false
defaults write com.apple.finder ShowStatusBar -bool false
defaults write com.apple.finder AppleShowAllFiles -bool false
killall Finder
defaults write NSGlobalDomain _HIHideMenuBar -bool false
mkdir -p "/Users/akitorahayashi/Desktop"
defaults write com.apple.screencapture location "/Users/akitorahayashi/Desktop"
killall SystemUIServer
echo "Mac のシステム設定が適用されました ✅"
