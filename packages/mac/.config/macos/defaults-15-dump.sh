#!/usr/bin/env bash
# macOS Defaults Reference Library - COMPREHENSIVE DUMP
# 
# Generated from: macOS 15.7.2
# Generated: 2025-11-16 01:18:26
# By: eden os dump
# 
# PURPOSE:
#   This is a REFERENCE file containing all discoverable macOS settings.
#   Use this to browse available options and copy what you want.
# 
# WORKFLOW:
#   1. Browse this file (search, ask LLM, etc.)
#   2. Copy settings you want to: defaults-15.sh
#   3. Uncomment and apply: eden os load
# 
# NOTE:
#   - ALL commands are commented out (this is a reference, not config)
#   - Includes system-managed settings (not just user preferences)
#   - May include app-specific settings

# ============================================================================
# Accessibility & Animations
# Domain: com.apple.Accessibility
# ============================================================================

# AXSClassicInvertColorsPreference
# Type: bool
# Value: 0
# Keywords: accessibility a x s classic invert colors preference
# defaults write "com.apple.Accessibility" "AXSClassicInvertColorsPreference" -bool false

# AccessibilityEnabled
# Type: bool
# Value: 0
# Keywords: accessibility accessibility enabled
# defaults write "com.apple.Accessibility" "AccessibilityEnabled" -bool false

# ApplicationAccessibilityEnabled
# Type: bool
# Value: 0
# Keywords: accessibility application accessibility enabled
# defaults write "com.apple.Accessibility" "ApplicationAccessibilityEnabled" -bool false

# AutomationEnabled
# Type: bool
# Value: 0
# Keywords: accessibility automation enabled
# defaults write "com.apple.Accessibility" "AutomationEnabled" -bool false

# BrailleInputDeviceConnected
# Type: bool
# Value: 0
# Keywords: accessibility braille input device connected
# defaults write "com.apple.Accessibility" "BrailleInputDeviceConnected" -bool false

# CommandAndControlEnabled
# Type: bool
# Value: 0
# Keywords: accessibility command and control enabled
# defaults write "com.apple.Accessibility" "CommandAndControlEnabled" -bool false

# DarkenSystemColors
# Type: bool
# Value: 0
# Keywords: accessibility darken system colors
# defaults write "com.apple.Accessibility" "DarkenSystemColors" -bool false

# DifferentiateWithoutColor
# Type: bool
# Value: 0
# Keywords: accessibility differentiate without color
# defaults write "com.apple.Accessibility" "DifferentiateWithoutColor" -bool false

# EnhancedBackgroundContrastEnabled
# Type: bool
# Value: 0
# Keywords: accessibility enhanced background contrast enabled
# defaults write "com.apple.Accessibility" "EnhancedBackgroundContrastEnabled" -bool false

# FullKeyboardAccessEnabled
# Type: bool
# Value: 0
# Keywords: accessibility full keyboard access enabled
# defaults write "com.apple.Accessibility" "FullKeyboardAccessEnabled" -bool false

# FullKeyboardAccessFocusRingEnabled
# Type: bool
# Value: 1
# Keywords: accessibility full keyboard access focus ring enabled
# defaults write "com.apple.Accessibility" "FullKeyboardAccessFocusRingEnabled" -bool true

# GenericAccessibilityClientEnabled
# Type: bool
# Value: 0
# Keywords: accessibility generic accessibility client enabled
# defaults write "com.apple.Accessibility" "GenericAccessibilityClientEnabled" -bool false

# GrayscaleDisplay
# Type: bool
# Value: 0
# Keywords: accessibility grayscale display
# defaults write "com.apple.Accessibility" "GrayscaleDisplay" -bool false

# InvertColorsEnabled
# Type: bool
# Value: 0
# Keywords: accessibility invert colors enabled
# defaults write "com.apple.Accessibility" "InvertColorsEnabled" -bool false

# KeyRepeatDelay
# Type: float
# Value: 0.5
# Keywords: accessibility key repeat delay
# defaults write "com.apple.Accessibility" "KeyRepeatDelay" -float 0.5

# KeyRepeatEnabled
# Type: bool
# Value: 1
# Keywords: accessibility key repeat enabled
# defaults write "com.apple.Accessibility" "KeyRepeatEnabled" -bool true

# KeyRepeatInterval
# Type: float
# Value: 0.03333333299999999
# Keywords: accessibility key repeat interval
# defaults write "com.apple.Accessibility" "KeyRepeatInterval" -float 0.03333333299999999

# ReduceMotionEnabled
# Type: bool
# Value: 1
# Keywords: accessibility reduce motion enabled
# defaults write "com.apple.Accessibility" "ReduceMotionEnabled" -bool true

# SpeakThisEnabled
# Type: bool
# Value: 0
# Keywords: accessibility speak this enabled
# defaults write "com.apple.Accessibility" "SpeakThisEnabled" -bool false

# VoiceOverTouchEnabled
# Type: bool
# Value: 0
# Keywords: accessibility voice over touch enabled
# defaults write "com.apple.Accessibility" "VoiceOverTouchEnabled" -bool false

# ============================================================================
# Trackpad & Mouse
# Domain: com.apple.AppleMultitouchMouse
# ============================================================================

# MouseButtonDivision
# Type: int
# Value: 55
# Keywords: apple multitouch mouse mouse button division
# defaults write "com.apple.AppleMultitouchMouse" "MouseButtonDivision" -int 55

# MouseButtonMode
# Type: string
# Value: OneButton
# Keywords: apple multitouch mouse mouse button mode
# defaults write "com.apple.AppleMultitouchMouse" "MouseButtonMode" -string "OneButton"

# MouseHorizontalScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch mouse mouse horizontal scroll
# defaults write "com.apple.AppleMultitouchMouse" "MouseHorizontalScroll" -bool true

# MouseMomentumScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch mouse mouse momentum scroll
# defaults write "com.apple.AppleMultitouchMouse" "MouseMomentumScroll" -bool true

# MouseOneFingerDoubleTapGesture
# Type: bool
# Value: 0
# Keywords: apple multitouch mouse mouse one finger double tap gesture
# defaults write "com.apple.AppleMultitouchMouse" "MouseOneFingerDoubleTapGesture" -bool false

# MouseTwoFingerDoubleTapGesture
# Type: int
# Value: 3
# Keywords: apple multitouch mouse mouse two finger double tap gesture
# defaults write "com.apple.AppleMultitouchMouse" "MouseTwoFingerDoubleTapGesture" -int 3

# MouseTwoFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: apple multitouch mouse mouse two finger horiz swipe gesture
# defaults write "com.apple.AppleMultitouchMouse" "MouseTwoFingerHorizSwipeGesture" -int 2

# MouseVerticalScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch mouse mouse vertical scroll
# defaults write "com.apple.AppleMultitouchMouse" "MouseVerticalScroll" -bool true

# UserPreferences
# Type: bool
# Value: 1
# Keywords: apple multitouch mouse user preferences
# defaults write "com.apple.AppleMultitouchMouse" "UserPreferences" -bool true

# version
# Type: bool
# Value: 1
# Keywords: apple multitouch mouse version
# defaults write "com.apple.AppleMultitouchMouse" "version" -bool true

# ============================================================================
# Trackpad & Mouse
# Domain: com.apple.AppleMultitouchTrackpad
# ============================================================================

# ActuateDetents
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad actuate detents
# defaults write "com.apple.AppleMultitouchTrackpad" "ActuateDetents" -bool true

# Clicking
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad clicking
# defaults write "com.apple.AppleMultitouchTrackpad" "Clicking" -bool false

# DragLock
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad drag lock
# defaults write "com.apple.AppleMultitouchTrackpad" "DragLock" -bool false

# Dragging
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad dragging
# defaults write "com.apple.AppleMultitouchTrackpad" "Dragging" -bool false

# FirstClickThreshold
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad first click threshold
# defaults write "com.apple.AppleMultitouchTrackpad" "FirstClickThreshold" -bool true

# ForceSuppressed
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad force suppressed
# defaults write "com.apple.AppleMultitouchTrackpad" "ForceSuppressed" -bool false

# SecondClickThreshold
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad second click threshold
# defaults write "com.apple.AppleMultitouchTrackpad" "SecondClickThreshold" -bool true

# TrackpadCornerSecondaryClick
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad trackpad corner secondary click
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadCornerSecondaryClick" -bool false

# TrackpadFiveFingerPinchGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad five finger pinch gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadFiveFingerPinchGesture" -int 2

# TrackpadFourFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad four finger horiz swipe gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadFourFingerHorizSwipeGesture" -int 2

# TrackpadFourFingerPinchGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad four finger pinch gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadFourFingerPinchGesture" -int 2

# TrackpadFourFingerVertSwipeGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad four finger vert swipe gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadFourFingerVertSwipeGesture" -int 2

# TrackpadHandResting
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad hand resting
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadHandResting" -bool true

# TrackpadHorizScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad horiz scroll
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadHorizScroll" -bool true

# TrackpadMomentumScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad momentum scroll
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadMomentumScroll" -bool true

# TrackpadPinch
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad pinch
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadPinch" -bool true

# TrackpadRightClick
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad right click
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadRightClick" -bool true

# TrackpadRotate
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad rotate
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadRotate" -bool true

# TrackpadScroll
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad scroll
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadScroll" -bool true

# TrackpadThreeFingerDrag
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad trackpad three finger drag
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerDrag" -bool false

# TrackpadThreeFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad three finger horiz swipe gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerHorizSwipeGesture" -int 2

# TrackpadThreeFingerTapGesture
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad trackpad three finger tap gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerTapGesture" -bool false

# TrackpadThreeFingerVertSwipeGesture
# Type: int
# Value: 2
# Keywords: apple multitouch trackpad trackpad three finger vert swipe gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadThreeFingerVertSwipeGesture" -int 2

# TrackpadTwoFingerDoubleTapGesture
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad trackpad two finger double tap gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadTwoFingerDoubleTapGesture" -bool true

# TrackpadTwoFingerFromRightEdgeSwipeGesture
# Type: int
# Value: 3
# Keywords: apple multitouch trackpad trackpad two finger from right edge swipe gesture
# defaults write "com.apple.AppleMultitouchTrackpad" "TrackpadTwoFingerFromRightEdgeSwipeGesture" -int 3

# USBMouseStopsTrackpad
# Type: bool
# Value: 0
# Keywords: apple multitouch trackpad u s b mouse stops trackpad
# defaults write "com.apple.AppleMultitouchTrackpad" "USBMouseStopsTrackpad" -bool false

# UserPreferences
# Type: bool
# Value: 1
# Keywords: apple multitouch trackpad user preferences
# defaults write "com.apple.AppleMultitouchTrackpad" "UserPreferences" -bool true

# version
# Type: int
# Value: 12
# Keywords: apple multitouch trackpad version
# defaults write "com.apple.AppleMultitouchTrackpad" "version" -int 12

# ============================================================================
# Apple System
# Domain: com.apple.HIToolbox
# ============================================================================

# AppleCurrentKeyboardLayoutInputSourceID
# Type: string
# Value: com.apple.keylayout.ABC
# Keywords: h i toolbox apple current keyboard layout input source i d
# defaults write "com.apple.HIToolbox" "AppleCurrentKeyboardLayoutInputSourceID" -string "com.apple.keylayout.ABC"

# AppleFnUsageType
# Type: bool
# Value: 1
# Keywords: h i toolbox apple fn usage type
# defaults write "com.apple.HIToolbox" "AppleFnUsageType" -bool true

# AppleInputSourceUpdateTime
# Type: string
# Value: 2025-11-15 15:39:10 +0000
# Keywords: h i toolbox apple input source update time
# defaults write "com.apple.HIToolbox" "AppleInputSourceUpdateTime" -string "2025-11-15 15:39:10 +0000"

# ============================================================================
# Apple System
# Domain: com.apple.SoftwareUpdate
# ============================================================================

# UserNotificationDate
# Type: string
# Value: 2025-10-31 23:44:48 +0000
# Keywords: software update user notification date
# defaults write "com.apple.SoftwareUpdate" "UserNotificationDate" -string "2025-10-31 23:44:48 +0000"

# ============================================================================
# Apple System
# Domain: com.apple.TextEdit
# ============================================================================

# ============================================================================
# Dock & Mission Control
# Domain: com.apple.dock
# ============================================================================

# autohide
# Type: bool
# Value: 1
# Keywords: dock autohide
# defaults write "com.apple.dock" "autohide" -bool true

# lastShowIndicatorTime
# Type: float
# Value: 784920814.280926
# Keywords: dock last show indicator time
# defaults write "com.apple.dock" "lastShowIndicatorTime" -float 784920814.280926

# loc
# Type: string
# Value: en_US:SE
# Keywords: dock loc
# defaults write "com.apple.dock" "loc" -string "en_US:SE"

# mod-count
# Type: int
# Value: 2459
# Keywords: dock mod count
# defaults write "com.apple.dock" "mod-count" -int 2459

# mru-spaces
# Type: bool
# Value: 0
# Keywords: dock mru spaces
# defaults write "com.apple.dock" "mru-spaces" -bool false

# orientation
# Type: string
# Value: left
# Keywords: dock orientation
# defaults write "com.apple.dock" "orientation" -string "left"

# region
# Type: string
# Value: SE
# Keywords: dock region
# defaults write "com.apple.dock" "region" -string "SE"

# tilesize
# Type: int
# Value: 16
# Keywords: dock tilesize
# defaults write "com.apple.dock" "tilesize" -int 16

# trash-full
# Type: bool
# Value: 1
# Keywords: dock trash full
# defaults write "com.apple.dock" "trash-full" -bool true

# version
# Type: bool
# Value: 1
# Keywords: dock version
# defaults write "com.apple.dock" "version" -bool true

# wvous-br-corner
# Type: int
# Value: 14
# Keywords: dock wvous br corner
# defaults write "com.apple.dock" "wvous-br-corner" -int 14

# ============================================================================
# Trackpad & Mouse
# Domain: com.apple.driver.AppleBluetoothMultitouch.mouse
# ============================================================================

# MouseButtonDivision
# Type: int
# Value: 55
# Keywords: driver apple bluetooth multitouch mouse mouse button division
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseButtonDivision" -int 55

# MouseButtonMode
# Type: string
# Value: OneButton
# Keywords: driver apple bluetooth multitouch mouse mouse button mode
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseButtonMode" -string "OneButton"

# MouseHorizontalScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch mouse mouse horizontal scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseHorizontalScroll" -bool true

# MouseMomentumScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch mouse mouse momentum scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseMomentumScroll" -bool true

# MouseOneFingerDoubleTapGesture
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch mouse mouse one finger double tap gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseOneFingerDoubleTapGesture" -bool false

# MouseTwoFingerDoubleTapGesture
# Type: int
# Value: 3
# Keywords: driver apple bluetooth multitouch mouse mouse two finger double tap gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseTwoFingerDoubleTapGesture" -int 3

# MouseTwoFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch mouse mouse two finger horiz swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseTwoFingerHorizSwipeGesture" -int 2

# MouseVerticalScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch mouse mouse vertical scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "MouseVerticalScroll" -bool true

# UserPreferences
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch mouse user preferences
# defaults write "com.apple.driver.AppleBluetoothMultitouch.mouse" "UserPreferences" -bool true

# ============================================================================
# Trackpad & Mouse
# Domain: com.apple.driver.AppleBluetoothMultitouch.trackpad
# ============================================================================

# Clicking
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad clicking
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Clicking" -bool false

# DragLock
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad drag lock
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "DragLock" -bool false

# Dragging
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad dragging
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "Dragging" -bool false

# TrackpadCornerSecondaryClick
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad trackpad corner secondary click
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadCornerSecondaryClick" -bool false

# TrackpadFiveFingerPinchGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad five finger pinch gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadFiveFingerPinchGesture" -int 2

# TrackpadFourFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad four finger horiz swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadFourFingerHorizSwipeGesture" -int 2

# TrackpadFourFingerPinchGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad four finger pinch gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadFourFingerPinchGesture" -int 2

# TrackpadFourFingerVertSwipeGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad four finger vert swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadFourFingerVertSwipeGesture" -int 2

# TrackpadHandResting
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad hand resting
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadHandResting" -bool true

# TrackpadHorizScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad horiz scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadHorizScroll" -bool true

# TrackpadMomentumScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad momentum scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadMomentumScroll" -bool true

# TrackpadPinch
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad pinch
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadPinch" -bool true

# TrackpadRightClick
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad right click
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadRightClick" -bool true

# TrackpadRotate
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad rotate
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadRotate" -bool true

# TrackpadScroll
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad scroll
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadScroll" -bool true

# TrackpadThreeFingerDrag
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad trackpad three finger drag
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerDrag" -bool false

# TrackpadThreeFingerHorizSwipeGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad three finger horiz swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerHorizSwipeGesture" -int 2

# TrackpadThreeFingerTapGesture
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad trackpad three finger tap gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerTapGesture" -bool false

# TrackpadThreeFingerVertSwipeGesture
# Type: int
# Value: 2
# Keywords: driver apple bluetooth multitouch trackpad trackpad three finger vert swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadThreeFingerVertSwipeGesture" -int 2

# TrackpadTwoFingerDoubleTapGesture
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad trackpad two finger double tap gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadTwoFingerDoubleTapGesture" -bool true

# TrackpadTwoFingerFromRightEdgeSwipeGesture
# Type: int
# Value: 3
# Keywords: driver apple bluetooth multitouch trackpad trackpad two finger from right edge swipe gesture
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "TrackpadTwoFingerFromRightEdgeSwipeGesture" -int 3

# USBMouseStopsTrackpad
# Type: bool
# Value: 0
# Keywords: driver apple bluetooth multitouch trackpad u s b mouse stops trackpad
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "USBMouseStopsTrackpad" -bool false

# UserPreferences
# Type: bool
# Value: 1
# Keywords: driver apple bluetooth multitouch trackpad user preferences
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "UserPreferences" -bool true

# version
# Type: int
# Value: 5
# Keywords: driver apple bluetooth multitouch trackpad version
# defaults write "com.apple.driver.AppleBluetoothMultitouch.trackpad" "version" -int 5

# ============================================================================
# Finder
# Domain: com.apple.finder
# ============================================================================

# DataSeparatedDisplayNameCache
# Type: string
# Value: 
# Keywords: finder data separated display name cache
# defaults write "com.apple.finder" "DataSeparatedDisplayNameCache" -string ""

# DownloadsFolderListViewSettingsVersion
# Type: bool
# Value: 1
# Keywords: finder downloads folder list view settings version
# defaults write "com.apple.finder" "DownloadsFolderListViewSettingsVersion" -bool true

# FK_AppCentricShowSidebar
# Type: bool
# Value: 1
# Keywords: finder f k app centric show sidebar
# defaults write "com.apple.finder" "FK_AppCentricShowSidebar" -bool true

# FK_SidebarWidth
# Type: int
# Value: 143
# Keywords: finder f k sidebar width
# defaults write "com.apple.finder" "FK_SidebarWidth" -int 143

# FXArrangeGroupViewBy
# Type: string
# Value: Name
# Keywords: finder f x arrange group view by
# defaults write "com.apple.finder" "FXArrangeGroupViewBy" -string "Name"

# FXDesktopTouchBarUpgradedToTenTwelveOne
# Type: bool
# Value: 1
# Keywords: finder f x desktop touch bar upgraded to ten twelve one
# defaults write "com.apple.finder" "FXDesktopTouchBarUpgradedToTenTwelveOne" -bool true

# FXDetachedDesktopProviderID
# Type: string
# Value: 
# Keywords: finder f x detached desktop provider i d
# defaults write "com.apple.finder" "FXDetachedDesktopProviderID" -string ""

# FXDetachedDocumentsProviderID
# Type: string
# Value: 
# Keywords: finder f x detached documents provider i d
# defaults write "com.apple.finder" "FXDetachedDocumentsProviderID" -string ""

# FXICloudDriveDesktop
# Type: bool
# Value: 0
# Keywords: finder f x i cloud drive desktop
# defaults write "com.apple.finder" "FXICloudDriveDesktop" -bool false

# FXICloudDriveDocuments
# Type: bool
# Value: 0
# Keywords: finder f x i cloud drive documents
# defaults write "com.apple.finder" "FXICloudDriveDocuments" -bool false

# FXICloudDriveEnabled
# Type: bool
# Value: 0
# Keywords: finder f x i cloud drive enabled
# defaults write "com.apple.finder" "FXICloudDriveEnabled" -bool false

# FXICloudLoggedIn
# Type: bool
# Value: 1
# Keywords: finder f x i cloud logged in
# defaults write "com.apple.finder" "FXICloudLoggedIn" -bool true

# FXPreferredSearchViewStyleVersion
# Type: string
# Value: %00%00%00%01
# Keywords: finder f x preferred search view style version
# defaults write "com.apple.finder" "FXPreferredSearchViewStyleVersion" -string "%00%00%00%01"

# FXPreferredViewStyle
# Type: string
# Value: Nlsv
# Keywords: finder f x preferred view style
# defaults write "com.apple.finder" "FXPreferredViewStyle" -string "Nlsv"

# FXQuickActionsConfigUpgradeLevel
# Type: int
# Value: 3
# Keywords: finder f x quick actions config upgrade level
# defaults write "com.apple.finder" "FXQuickActionsConfigUpgradeLevel" -int 3

# FXSidebarUpgradedSharedSearchToTwelve
# Type: bool
# Value: 1
# Keywords: finder f x sidebar upgraded shared search to twelve
# defaults write "com.apple.finder" "FXSidebarUpgradedSharedSearchToTwelve" -bool true

# FXSidebarUpgradedToTenFourteen
# Type: bool
# Value: 1
# Keywords: finder f x sidebar upgraded to ten fourteen
# defaults write "com.apple.finder" "FXSidebarUpgradedToTenFourteen" -bool true

# FXSidebarUpgradedToTenTen
# Type: bool
# Value: 1
# Keywords: finder f x sidebar upgraded to ten ten
# defaults write "com.apple.finder" "FXSidebarUpgradedToTenTen" -bool true

# FXToolbarUpgradedToTenEight
# Type: bool
# Value: 1
# Keywords: finder f x toolbar upgraded to ten eight
# defaults write "com.apple.finder" "FXToolbarUpgradedToTenEight" -bool true

# FXToolbarUpgradedToTenNine
# Type: int
# Value: 2
# Keywords: finder f x toolbar upgraded to ten nine
# defaults write "com.apple.finder" "FXToolbarUpgradedToTenNine" -int 2

# FXToolbarUpgradedToTenSeven
# Type: bool
# Value: 1
# Keywords: finder f x toolbar upgraded to ten seven
# defaults write "com.apple.finder" "FXToolbarUpgradedToTenSeven" -bool true

# LastTrashState
# Type: bool
# Value: 1
# Keywords: finder last trash state
# defaults write "com.apple.finder" "LastTrashState" -bool true

# ShowSidebar
# Type: bool
# Value: 0
# Keywords: finder show sidebar
# defaults write "com.apple.finder" "ShowSidebar" -bool false

# ShowStatusBar
# Type: bool
# Value: 1
# Keywords: finder show status bar
# defaults write "com.apple.finder" "ShowStatusBar" -bool true

# RecentsArrangeGroupViewBy
# Type: string
# Value: Date Last Opened
# Keywords: finder recents arrange group view by
# defaults write "com.apple.finder" "RecentsArrangeGroupViewBy" -string "Date Last Opened"

# SearchRecentsSavedViewStyleVersion
# Type: string
# Value: %00%00%00%01
# Keywords: finder search recents saved view style version
# defaults write "com.apple.finder" "SearchRecentsSavedViewStyleVersion" -string "%00%00%00%01"

# ShowSidebar
# Type: bool
# Value: 0
# Keywords: finder show sidebar
# defaults write "com.apple.finder" "ShowSidebar" -bool false

# ShowStatusBar
# Type: bool
# Value: 1
# Keywords: finder show status bar
# defaults write "com.apple.finder" "ShowStatusBar" -bool true

# ShowSidebar
# Type: bool
# Value: 0
# Keywords: finder show sidebar
# defaults write "com.apple.finder" "ShowSidebar" -bool false

# ShowStatusBar
# Type: bool
# Value: 1
# Keywords: finder show status bar
# defaults write "com.apple.finder" "ShowStatusBar" -bool true

# ShowExternalHardDrivesOnDesktop
# Type: bool
# Value: 1
# Keywords: finder show external hard drives on desktop
# defaults write "com.apple.finder" "ShowExternalHardDrivesOnDesktop" -bool true

# ShowHardDrivesOnDesktop
# Type: bool
# Value: 0
# Keywords: finder show hard drives on desktop
# defaults write "com.apple.finder" "ShowHardDrivesOnDesktop" -bool false

# ShowPathbar
# Type: bool
# Value: 1
# Keywords: finder show pathbar
# defaults write "com.apple.finder" "ShowPathbar" -bool true

# ShowRemovableMediaOnDesktop
# Type: bool
# Value: 1
# Keywords: finder show removable media on desktop
# defaults write "com.apple.finder" "ShowRemovableMediaOnDesktop" -bool true

# ShowSidebar
# Type: bool
# Value: 0
# Keywords: finder show sidebar
# defaults write "com.apple.finder" "ShowSidebar" -bool false

# ShowStatusBar
# Type: bool
# Value: 1
# Keywords: finder show status bar
# defaults write "com.apple.finder" "ShowStatusBar" -bool true

# SidebarDevicesSectionDisclosedState
# Type: bool
# Value: 1
# Keywords: finder sidebar devices section disclosed state
# defaults write "com.apple.finder" "SidebarDevicesSectionDisclosedState" -bool true

# SidebarPlacesSectionDisclosedState
# Type: bool
# Value: 1
# Keywords: finder sidebar places section disclosed state
# defaults write "com.apple.finder" "SidebarPlacesSectionDisclosedState" -bool true

# SidebarShowingSignedIntoiCloud
# Type: bool
# Value: 1
# Keywords: finder sidebar showing signed intoi cloud
# defaults write "com.apple.finder" "SidebarShowingSignedIntoiCloud" -bool true

# SidebarShowingiCloudDesktop
# Type: bool
# Value: 0
# Keywords: finder sidebar showingi cloud desktop
# defaults write "com.apple.finder" "SidebarShowingiCloudDesktop" -bool false

# SidebarWidth
# Type: int
# Value: 128
# Keywords: finder sidebar width
# defaults write "com.apple.finder" "SidebarWidth" -int 128

# TagsCloudSerialNumber
# Type: bool
# Value: 1
# Keywords: finder tags cloud serial number
# defaults write "com.apple.finder" "TagsCloudSerialNumber" -bool true

# ShowSidebar
# Type: bool
# Value: 0
# Keywords: finder show sidebar
# defaults write "com.apple.finder" "ShowSidebar" -bool false

# ShowStatusBar
# Type: bool
# Value: 1
# Keywords: finder show status bar
# defaults write "com.apple.finder" "ShowStatusBar" -bool true

# ============================================================================
# Apple System
# Domain: com.apple.keyboardservicesd
# ============================================================================

# CKStartupTime
# Type: int
# Value: 1762296022
# Keywords: keyboardservicesd c k startup time
# defaults write "com.apple.keyboardservicesd" "CKStartupTime" -int 1762296022

# ============================================================================
# Apple System
# Domain: com.apple.loginwindow
# ============================================================================

# MiniBuddyLaunch
# Type: bool
# Value: 0
# Keywords: loginwindow mini buddy launch
# defaults write "com.apple.loginwindow" "MiniBuddyLaunch" -bool false

# TALLogoutReason
# Type: string
# Value: Restart
# Keywords: loginwindow t a l logout reason
# defaults write "com.apple.loginwindow" "TALLogoutReason" -string "Restart"

# TALLogoutSavesState
# Type: bool
# Value: 0
# Keywords: loginwindow t a l logout saves state
# defaults write "com.apple.loginwindow" "TALLogoutSavesState" -bool false

# oneTimeSSMigrationComplete
# Type: bool
# Value: 1
# Keywords: loginwindow one time s s migration complete
# defaults write "com.apple.loginwindow" "oneTimeSSMigrationComplete" -bool true

# ============================================================================
# Menu Bar
# Domain: com.apple.menuextra.clock
# ============================================================================

# ShowAMPM
# Type: bool
# Value: 1
# Keywords: menuextra clock show a m p m
# defaults write "com.apple.menuextra.clock" "ShowAMPM" -bool true

# ShowDate
# Type: bool
# Value: 0
# Keywords: menuextra clock show date
# defaults write "com.apple.menuextra.clock" "ShowDate" -bool false

# ShowDayOfWeek
# Type: bool
# Value: 1
# Keywords: menuextra clock show day of week
# defaults write "com.apple.menuextra.clock" "ShowDayOfWeek" -bool true

# ============================================================================
# Menu Bar
# Domain: com.apple.menuextra.textinput
# ============================================================================

# ModeNameVisible
# Type: bool
# Value: 0
# Keywords: menuextra textinput mode name visible
# defaults write "com.apple.menuextra.textinput" "ModeNameVisible" -bool false

# ============================================================================
# Apple System
# Domain: com.apple.preferences.softwareupdate
# ============================================================================

# ============================================================================
# Screenshots
# Domain: com.apple.screencapture
# ============================================================================

# last-analytics-stamp
# Type: float
# Value: 784460051.555463
# Keywords: screencapture last analytics stamp
# defaults write "com.apple.screencapture" "last-analytics-stamp" -float 784460051.555463

# ============================================================================
# Screen Saver & Security
# Domain: com.apple.screensaver
# ============================================================================

# tokenRemovalAction
# Type: bool
# Value: 0
# Keywords: screensaver token removal action
# defaults write "com.apple.screensaver" "tokenRemovalAction" -bool false

# ============================================================================
# Apple System
# Domain: com.apple.symbolichotkeys
# ============================================================================

# ============================================================================
# Apple System
# Domain: com.apple.systempreferences
# ============================================================================

# ThirdPartyCount
# Type: bool
# Value: 0
# Keywords: systempreferences third party count
# defaults write "com.apple.systempreferences" "ThirdPartyCount" -bool false

# ============================================================================
# Apple System
# Domain: com.apple.systempreferences.AppleIDSettings
# ============================================================================

# CKStartupTime
# Type: int
# Value: 1762296016
# Keywords: systempreferences apple i d settings c k startup time
# defaults write "com.apple.systempreferences.AppleIDSettings" "CKStartupTime" -int 1762296016

# ============================================================================
# Apple System
# Domain: com.apple.systempreferences.SpotlightIndexExtension
# ============================================================================

# ThirdPartyCount
# Type: bool
# Value: 0
# Keywords: systempreferences spotlight index extension third party count
# defaults write "com.apple.systempreferences.SpotlightIndexExtension" "ThirdPartyCount" -bool false

# ============================================================================
# Accessibility & Animations
# Domain: com.apple.universalaccess
# ============================================================================

# closeViewHotkeysEnabled
# Type: bool
# Value: 0
# Keywords: universalaccess close view hotkeys enabled
# defaults write "com.apple.universalaccess" "closeViewHotkeysEnabled" -bool false

# closeViewZoomDisplayID
# Type: bool
# Value: 0
# Keywords: universalaccess close view zoom display i d
# defaults write "com.apple.universalaccess" "closeViewZoomDisplayID" -bool false

# closeViewZoomFactor
# Type: bool
# Value: 1
# Keywords: universalaccess close view zoom factor
# defaults write "com.apple.universalaccess" "closeViewZoomFactor" -bool true

# customFonts
# Type: bool
# Value: 0
# Keywords: universalaccess custom fonts
# defaults write "com.apple.universalaccess" "customFonts" -bool false

# grayscale
# Type: bool
# Value: 0
# Keywords: universalaccess grayscale
# defaults write "com.apple.universalaccess" "grayscale" -bool false

# hudNotifiedConstrast
# Type: bool
# Value: 0
# Keywords: universalaccess hud notified constrast
# defaults write "com.apple.universalaccess" "hudNotifiedConstrast" -bool false

# login
# Type: bool
# Value: 0
# Keywords: universalaccess login
# defaults write "com.apple.universalaccess" "login" -bool false

# reduceMotion
# Type: bool
# Value: 1
# Keywords: universalaccess reduce motion
# defaults write "com.apple.universalaccess" "reduceMotion" -bool true

# sessionChange
# Type: bool
# Value: 0
# Keywords: universalaccess session change
# defaults write "com.apple.universalaccess" "sessionChange" -bool false


# ============================================================================
# End of Reference Library
# Total Settings: 173
# ============================================================================

