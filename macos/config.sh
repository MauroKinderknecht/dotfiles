#!/bin/bash

# macOS-specific defaults and configuration

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
source "$DOTFILES_DIR/_logger.sh"
source "$DOTFILES_DIR/_utils.sh"

e_message "Setting macOS defaults"

# Close any open System Preferences window to prevent overriding settings
osascript -e 'tell application "System Preferences" to quit'

# Menu bar: hide the useless Time Machine and Volume icons
defaults write com.apple.systemuiserver menuExtras -array "/System/Library/CoreServices/Menu Extras/Bluetooth.menu" "/System/Library/CoreServices/Menu Extras/AirPort.menu" "/System/Library/CoreServices/Menu Extras/Battery.menu" "/System/Library/CoreServices/Menu Extras/Clock.menu"

# Show scrollbars only when scrolling
defaults write NSGlobalDomain AppleShowScrollBars -string "WhenScrolling"

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Disable Resume system-wide so a restart is a true restart
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false

# Automatically illuminate built-in MacBook keyboard in low light
defaults write com.apple.BezelServices kDim -bool true

# Turn off keyboard illumination when computer is not used for 5 minutes
defaults write com.apple.BezelServices kDimTime -int 300

# Save screenshots in PNG format (other options: BMP, GIF, JPG, PDF, TIFF)
defaults write com.apple.screencapture type -string "png"

# Do not how icons for hard drives, servers, and removable media on the desktop
defaults write com.apple.finder ShowExternalHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowHardDrivesOnDesktop -bool false
defaults write com.apple.finder ShowMountedServersOnDesktop -bool false
defaults write com.apple.finder ShowRemovableMediaOnDesktop -bool false

# Disable the warning before emptying the Trash
defaults write com.apple.finder WarnOnEmptyTrash -bool false

# Empty Trash securely by default
defaults write com.apple.finder EmptyTrashSecurely -bool true

# Show menu bar when inside a full screen app
defaults write NSGlobalDomain AppleMenuBarVisibleInFullscreen -boolean true

# Disable auto capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -boolean false

# Disable auto period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -boolean false

# Finder: show hidden files by default
defaults write com.apple.Finder AppleShowAllFiles -bool true

# Finder: show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Finder: show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Do nothing when double-clicking
defaults write NSGlobalDomain AppleActionOnDoubleClick -string "None"

# Use current directory as default search scope in Finder
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Avoid creating .DS_Store files on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true

# Enable snap-to-grid for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:arrangeBy grid" ~/Library/Preferences/com.apple.finder.plist

# Increase grid spacing for icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:gridSpacing 100" ~/Library/Preferences/com.apple.finder.plist

# Increase the size of icons on the desktop and in other icon views
/usr/libexec/PlistBuddy -c "Set :DesktopViewSettings:IconViewSettings:iconSize 60" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :FK_StandardViewSettings:IconViewSettings:iconSize 60" ~/Library/Preferences/com.apple.finder.plist
/usr/libexec/PlistBuddy -c "Set :StandardViewSettings:IconViewSettings:iconSize 60" ~/Library/Preferences/com.apple.finder.plist

# Use list view in all Finder windows by default
# Four-letter codes for the other view modes: `icnv`, `clmv`, `Flwv`
defaults write com.apple.Finder FXPreferredViewStyle -string "Nlsv"

# Dock: auto hide
defaults write com.apple.dock autohide -boolean true

# Dock: set double-click behavior to none
defaults write com.apple.dock dblclickbehavior -string "none"

# Dock: set icon size
defaults write com.apple.dock largesize -integer 80

# Dock: set launch animation
defaults write com.apple.dock launchanim -boolean true

# Dock: set magnification
defaults write com.apple.dock magnification -boolean true

# Dock: set minimize effect
defaults write com.apple.dock mineffect -string "genie"

# Dock: set minimize to application
defaults write com.apple.dock minimize-to-application -boolean true

# Dock: set process indicators
defaults write com.apple.dock show-process-indicators -boolean true

# Dock: do not show recent applications
defaults write com.apple.dock show-recents -boolean false

# Dock: set static-only
defaults write com.apple.dock static-only -boolean true

# Dock: set tile size
defaults write com.apple.dock tilesize -integer 60

# Kill all affected applications
for app in Finder Dock; do
	killall "$app" &> /dev/null 2>&1
done

e_message "Setting folder structure"

# Configure folder structure
if ! has_path "files"; then
  e_pending "Creating ~/files folder"
  mkdir -p ~/files ~/files/sandbox ~/files/projects ~/files/work
fi
