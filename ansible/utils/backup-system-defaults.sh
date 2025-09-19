#!/bin/bash
set -euo pipefail

# Get the configuration directory path from script arguments
CONFIG_DIR_PROPS="$1"
if [ -z "$CONFIG_DIR_PROPS" ]; then
    echo "[ERROR] This script requires a configuration directory path as its first argument." >&2
    exit 1
fi

# CONFIG_DIR_PROPS is now passed as absolute path from just

# ================================================
# Retrieve current macOS system defaults and generate system-defaults.sh
# ================================================
#
# Usage:
# 1. Grant execution permission:
#    $ chmod +x scripts/backup-system-defaults.sh
# 2. Run the script:
#    $ ./scripts/backup-system-defaults.sh
#
# The script will create/update config/common/system-defaults/system-defaults.sh with current macOS system defaults.
#
# ================================================

# ================================================
# Initial setup and file path configuration
# ================================================

OUTPUT_FILE="$CONFIG_DIR_PROPS/system-defaults/system-defaults.yml"

OUTPUT_DIR="$(dirname "$OUTPUT_FILE")"
mkdir -p "$OUTPUT_DIR"

echo "Retrieving current macOS system defaults and generating $OUTPUT_FILE..."

# Remove existing system defaults file
if [ -f "$OUTPUT_FILE" ]; then
    rm "$OUTPUT_FILE"
    echo "Removed existing system defaults file: $OUTPUT_FILE"
fi

# Start YAML array
cat <<EOF > "$OUTPUT_FILE"
---
EOF

# ================================================
# Utility function definitions
# ================================================

# Function to get value and fallback to default if it doesn't exist
get_default_value() {
    local value
    value=$(defaults read "$1" "$2" 2>/dev/null) || value="$3"
    echo "$value"
}

# Function to convert bool values to appropriate format
format_bool_value() {
    local value
    value="$(echo "$1" | tr '[:upper:]' '[:lower:]' | xargs)"
    case "$value" in
        1|true) echo "true" ;;
        0|false) echo "false" ;;
        *) echo "$value" ;;
    esac
}

# Function to add YAML setting
add_yaml_setting() {
    local key="$1"
    local domain="$2"
    local type="$3"
    local value="$4"
    local comment="$5"

    if [ -n "$comment" ]; then
        echo "  # ${comment}" >> "$OUTPUT_FILE"
    fi

    if [ "$domain" = "NSGlobalDomain" ]; then
        echo "- { key: '${key}', type: '${type}', value: ${value} }" >> "$OUTPUT_FILE"
    else
        echo "- { key: '${key}', domain: '${domain}', type: '${type}', value: ${value} }" >> "$OUTPUT_FILE"
    fi
}

# ================================================
# Settings definition array
# ================================================

# Array format: "key domain type default_value comment"
# Use underscores in default values and comments to avoid space parsing issues
SETTINGS=(
    # System settings
    "AppleHighlightColor NSGlobalDomain string 0.764700_0.976500_0.568600 System_settings"
    "AppleShowScrollBars NSGlobalDomain string Automatic"
    "NSNavPanelExpandedStateForSaveMode NSGlobalDomain bool false"
    "NSNavPanelExpandedStateForSaveMode2 NSGlobalDomain bool false"
    "PMPrintingExpandedStateForPrint NSGlobalDomain bool false"
    "PMPrintingExpandedStateForPrint2 NSGlobalDomain bool false"
    "NSDocumentSaveNewDocumentsToCloud NSGlobalDomain bool true"
    "NSQuitAlwaysKeepsWindows com.apple.systempreferences bool false"
    "NSDisableAutomaticTermination NSGlobalDomain bool false"
    "LSQuarantine com.apple.LaunchServices bool true"
    "DialogType com.apple.CrashReporter string none"

    # UI/UX
    "_HIHideMenuBar NSGlobalDomain bool false UI/UX"
    "NSTableViewDefaultSizeMode NSGlobalDomain int 2"
    "NSWindowResizeTime NSGlobalDomain float 0.001"
    "NSAutomaticCapitalizationEnabled NSGlobalDomain bool true"
    "NSAutomaticDashSubstitutionEnabled NSGlobalDomain bool true"
    "NSAutomaticPeriodSubstitutionEnabled NSGlobalDomain bool true"
    "NSAutomaticQuoteSubstitutionEnabled NSGlobalDomain bool true"
    "NSAutomaticSpellingCorrectionEnabled NSGlobalDomain bool true"
    "WebKitDeveloperExtras NSGlobalDomain bool false"
    "AppleEnableSwipeNavigateWithScrolls NSGlobalDomain bool false"

    # Dock
    "tilesize com.apple.dock int 50 Dock"
    "autohide com.apple.dock bool false"
    "autohide-time-modifier com.apple.dock float 0.5"
    "autohide-delay com.apple.dock float 0"
    "show-recents com.apple.dock bool true"
    "mineffect com.apple.dock string genie"
    "minimize-to-application com.apple.dock bool false"
    "static-only com.apple.dock bool false"
    "scroll-to-open com.apple.dock bool false"
    "launchanim com.apple.dock bool true"
    "showhidden com.apple.dock bool false"
    "no-bouncing com.apple.dock bool false"

    # Finder
    "ShowPathbar com.apple.finder bool false Finder"
    "ShowStatusBar com.apple.finder bool false"
    "AppleShowAllFiles com.apple.finder bool false"
    "AppleShowAllExtensions NSGlobalDomain bool false"
    "_FXShowPosixPathInTitle com.apple.finder bool false"
    "FXPreferredViewStyle com.apple.finder string Nlsv"
    "_FXSortFoldersFirst com.apple.finder bool false"
    "FXDefaultSearchScope com.apple.finder string SCev"
    "FXEnableExtensionChangeWarning com.apple.finder bool true"
    "WarnOnEmptyTrash com.apple.finder bool true"
    "FXRemoveOldTrashItems com.apple.finder bool false"
    "DSDontWriteNetworkStores com.apple.desktopservices bool false"
    "QuitMenuItem com.apple.finder bool false"
    "DisableAllAnimations com.apple.finder bool false"
    "com.apple.springing.enabled NSGlobalDomain bool false"

    # Desktop
    "ShowExternalHardDrivesOnDesktop com.apple.finder bool true Desktop"
    "EnableStandardClickToShowDesktop com.apple.WindowManager bool false"
    "GloballyEnabled com.apple.WindowManager bool false"

    # Mission Control
    "expose-animation-duration com.apple.dock float 0.2 Mission_Control"
    "mru-spaces com.apple.dock bool true"
    "expose-group-by-app com.apple.dock bool true"
    "workspaces-auto-swoosh com.apple.dock bool false"
    "spans-displays com.apple.spaces bool false"

    # Hot Corners
    "wvous-tl-corner com.apple.dock int 1 Hot_Corners"
    "wvous-tr-corner com.apple.dock int 1"
    "wvous-bl-corner com.apple.dock int 1"
    "wvous-br-corner com.apple.dock int 1"

    # Keyboard
    "KeyRepeat NSGlobalDomain int 2 Keyboard"
    "InitialKeyRepeat NSGlobalDomain int 15"
    "ApplePressAndHoldEnabled NSGlobalDomain bool true"
    "AppleKeyboardUIMode NSGlobalDomain int 1"
    "com.apple.keyboard.fnState NSGlobalDomain bool false"
    "com.apple.swipescrolldirection NSGlobalDomain bool true"

    # Mouse
    "com.apple.mouse.scaling .GlobalPreferences float 1.0 Mouse"
    "FocusFollowsMouse com.apple.Terminal bool false"

    # Trackpad
    "com.apple.trackpad.scaling NSGlobalDomain float 1.5 Trackpad"
    "Clicking com.apple.AppleMultitouchTrackpad bool 1"
    "Dragging com.apple.AppleMultitouchTrackpad bool 0"
    "TrackpadThreeFingerDrag com.apple.AppleMultitouchTrackpad bool 0"
    "FirstClickThreshold com.apple.AppleMultitouchTrackpad int 1"
    "ForceSuppressed com.apple.AppleMultitouchTrackpad bool false"
    "TrackpadThreeFingerTapGesture com.apple.AppleMultitouchTrackpad int 2"
    "TrackpadRightClick com.apple.AppleMultitouchTrackpad bool true"

    # Sound
    "com.apple.sound.uiaudio.enabled com.apple.systemsound int 1 Sound"
    "com.apple.sound.beep.feedback NSGlobalDomain int 1"
    "com.apple.sound.beep.sound NSGlobalDomain string"
    "Apple_Bitpool_Min_(editable) com.apple.BluetoothAudioAgent int 40"

    # Screenshots
    "location com.apple.screencapture string \$HOME/Desktop Screenshots"
    "disable-shadow com.apple.screencapture bool false"
    "include-date com.apple.screencapture bool false"
    "show-thumbnail com.apple.screencapture bool true"
    "type com.apple.screencapture string png"
)

# ================================================
# Special cases that need custom handling
# ================================================

# Handle startup sound (uses nvram instead of defaults)
STARTUP_SOUND=$(nvram SystemAudioVolume 2>/dev/null | awk '{print $NF}' || echo " ")

# ================================================
# YAML setting generation
# ================================================

# Process all settings from the array
for setting in "${SETTINGS[@]}"; do
    # Parse the setting string
    IFS=' ' read -r key domain type default_val comment <<< "$setting"

    # Handle special cases for value retrieval
    if [[ "$key" == "com.apple.keyboard.fnState" ]] || [[ "$key" == "com.apple.trackpad.scaling" ]] || [[ "$key" == "com.apple.sound.beep.feedback" ]] || [[ "$key" == "com.apple.sound.beep.sound" ]]; then
        # These keys use -g flag
        value=$(get_default_value -g "$key" "$default_val")
    else
        # Standard defaults read
        # Convert underscores back to spaces in default values
        default_val_with_spaces="${default_val//_/ }"
        value=$(get_default_value "$domain" "$key" "$default_val_with_spaces")
    fi

    # Special handling for Apple Bitpool key (has spaces and parentheses)
    if [[ "$key" == "Apple_Bitpool_Min_(editable)" ]]; then
        key="Apple Bitpool Min (editable)"
    fi

    # Format the value based on type
    case "$type" in
        "bool")
            formatted_value="$(format_bool_value "$value")"
            ;;
        "string")
            # Special case for screenshot location - apply HOME substitution
            if [[ "$key" == "location" ]]; then
                value_escaped="${value/#$HOME/\$HOME}"
                formatted_value="'$value_escaped'"
            else
                formatted_value="'$value'"
            fi
            ;;
        *)
            formatted_value="$value"
            ;;
    esac

    # Convert underscores back to spaces in comments
    comment_with_spaces="${comment//_/ }"

    # Add the setting to YAML
    add_yaml_setting "$key" "$domain" "$type" "$formatted_value" "$comment_with_spaces"
done

echo "Generated system defaults script: $OUTPUT_FILE"
