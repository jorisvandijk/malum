<!-- Made from MacOSCatalog by `swift run MalumDocs`. Edit the catalog, not this page. -->

# macOS settings reference

Every macOS setting `macos.toml` takes, by table. Each one has a name you can read, and Malum writes the preferences macOS keeps it in, which it lists under "Writes" for when you want to check one with `defaults read`. A setting that isn't here isn't one Malum manages yet: it's added to the catalog, not set by its raw name.

A setting you leave out is left as it is. One Malum set before and you take out goes back to macOS's own. A name a table doesn't take gets a warning.

Malum always turns macOS's own window tiling off, since its window manager tiles: dragging a window to an edge or the top of the screen, or holding Option, doesn't tile it.

`[preferences]` and `[current_host]`, which took preferences by the names macOS stores them under, still work for one release, with a warning that names the setting to use instead.

## `[appearance]`

Light or dark, the accent colour and scroll bars. System Settings, Appearance.

### `mode`

Light, dark, or switching between them through the day, which macOS does itself.

- Value: "light", "dark" or "auto"
- Writes: `NSGlobalDomain` `AppleInterfaceStyle`, `NSGlobalDomain` `AppleInterfaceStyleSwitchesAutomatically`

### `accent_color`

The colour of buttons, selections and highlights.

- Value: "multicolor", "graphite", "red", "orange", "yellow", "green", "blue", "purple" or "pink"
- Writes: `NSGlobalDomain` `AppleAccentColor`

### `scroll_bars`

When scroll bars show.

- Value: "automatic", "when_scrolling" or "always"
- Writes: `NSGlobalDomain` `AppleShowScrollBars`

## `[menu_bar]`

When the menu bar hides and which items it shows. System Settings, Menu Bar.

### `hide`

When the menu bar hides until the pointer reaches the top of the screen.

- Value: "never", "in_full_screen", "on_desktop" or "always"
- Writes: `NSGlobalDomain` `_HIHideMenuBar`, `NSGlobalDomain` `AppleMenuBarVisibleInFullscreen`

### `show_spotlight`

Shows the Spotlight icon.

- Value: true or false
- Writes: `com.apple.Spotlight (current host)` `MenuItemHidden`

### `show_now_playing`

Shows Now Playing.

- Value: true or false
- Writes: `com.apple.controlcenter (current host)` `NowPlaying`

### `show_timer`

Shows the timer.

- Value: true or false
- Writes: `com.apple.controlcenter (current host)` `Timer`

### `show_input_menu`

Shows the input menu, to switch keyboard layouts.

- Value: true or false
- Writes: `com.apple.TextInputMenu` `visible`

## `[clock]`

The clock in the menu bar. System Settings, Control Center, Clock Options.

### `show_am_pm`

Shows AM or PM after the time.

- Value: true or false
- Writes: `com.apple.menuextra.clock` `ShowAMPM`

### `show_day_of_week`

Shows the day of the week.

- Value: true or false
- Writes: `com.apple.menuextra.clock` `ShowDayOfWeek`

## `[sound]`

Alert and interface sounds. System Settings, Sound.

### `alert_volume`

How loud the alert sound is, as a percentage of the output volume.

- Value: a whole number from 0 to 100
- Writes: `NSGlobalDomain` `com.apple.sound.beep.volume`

### `ui_sounds`

Plays sounds for actions such as emptying the Trash.

- Value: true or false
- Writes: `NSGlobalDomain` `com.apple.sound.uiaudio.enabled`

## `[pointer]`

What the mouse and the trackpad share. System Settings, Mouse and Trackpad.

### `natural_scrolling`

Content follows your fingers, as on a phone. macOS sets it for the mouse too.

- Value: true or false
- Writes: `NSGlobalDomain` `com.apple.swipescrolldirection`

### `shake_to_locate`

Makes the pointer bigger for a moment when you shake it.

- Value: true or false
- Writes: `NSGlobalDomain` `CGDisableCursorLocationMagnification`

## `[trackpad]`

The built-in trackpad and the Magic Trackpad. System Settings, Trackpad.

### `tap_to_click`

A tap clicks, without pressing the trackpad down.

- Value: true or false
- Writes: `com.apple.AppleMultitouchTrackpad` `Clicking`, `com.apple.driver.AppleBluetoothMultitouch.trackpad` `Clicking`

### `three_finger_drag`

Drags windows and selections with three fingers. Accessibility, Pointer Control.

- Value: true or false
- Writes: `com.apple.AppleMultitouchTrackpad` `TrackpadThreeFingerDrag`, `com.apple.driver.AppleBluetoothMultitouch.trackpad` `TrackpadThreeFingerDrag`

### `force_click`

A harder press looks things up or previews them.

- Value: true or false
- Writes: `NSGlobalDomain` `com.apple.trackpad.forceClick`

## `[keyboard]`

Key repeat, the backlight and the keyboard layouts. System Settings, Keyboard.

### `repeat_delay_ms`

How long a key is held before it starts repeating, in milliseconds.

- Value: milliseconds from 15 to 1800, in steps of 15
- Writes: `NSGlobalDomain` `InitialKeyRepeat`

### `repeat_interval_ms`

The time between repeats of a held key, in milliseconds.

- Value: milliseconds from 15 to 1800, in steps of 15
- Writes: `NSGlobalDomain` `KeyRepeat`

### `auto_backlight`

Turns the keyboard's backlight on in low light.

- Value: true or false
- Writes: `com.apple.BezelServices` `dAuto`

### `input_sources`

The keyboard layouts you switch between, the first one in use.

- Value: a list of at least one keyboard layout, each "us", "us_international", "abc", "british", "dutch", "german", "french", "dvorak" or "colemak"
- Writes: `com.apple.HIToolbox` `AppleEnabledInputSources`

## `[text]`

What macOS changes as you type. System Settings, Keyboard, Text Input.

### `auto_correct`

Corrects spelling as you type, in apps and on web pages.

- Value: true or false
- Writes: `NSGlobalDomain` `NSAutomaticSpellingCorrectionEnabled`, `NSGlobalDomain` `WebAutomaticSpellingCorrectionEnabled`

### `auto_capitalize`

Starts sentences with a capital.

- Value: true or false
- Writes: `NSGlobalDomain` `NSAutomaticCapitalizationEnabled`

### `auto_period`

Two spaces type a period.

- Value: true or false
- Writes: `NSGlobalDomain` `NSAutomaticPeriodSubstitutionEnabled`

### `smart_dashes`

Two hyphens become a dash.

- Value: true or false
- Writes: `NSGlobalDomain` `NSAutomaticDashSubstitutionEnabled`

### `smart_quotes`

Straight quotes become curly ones.

- Value: true or false
- Writes: `NSGlobalDomain` `NSAutomaticQuoteSubstitutionEnabled`

## `[finder]`

Finder's windows and files. Finder, Settings, and the View menu.

### `show_extensions`

Shows every file's extension.

- Value: true or false
- Writes: `NSGlobalDomain` `AppleShowAllExtensions`

### `warn_on_extension_change`

Asks before a file's extension changes.

- Value: true or false
- Writes: `com.apple.finder` `FXEnableExtensionChangeWarning`

### `search_scope`

Where a search in a Finder window looks.

- Value: "this_mac", "current_folder" or "previous"
- Writes: `com.apple.finder` `FXDefaultSearchScope`

### `view`

How new Finder windows show their files.

- Value: "icons", "list", "columns" or "gallery"
- Writes: `com.apple.finder` `FXPreferredViewStyle`

### `new_window`

The folder a new Finder window opens.

- Value: "home", "desktop", "documents" or "computer"
- Writes: `com.apple.finder` `NewWindowTarget`

### `empty_old_trash`

Removes items from the Trash after 30 days.

- Value: true or false
- Writes: `com.apple.finder` `FXRemoveOldTrashItems`

### `quit_menu_item`

Adds Quit Finder to Finder's menu.

- Value: true or false
- Writes: `com.apple.finder` `QuitMenuItem`

### `show_path_bar`

Shows the folder path at the bottom of windows.

- Value: true or false
- Writes: `com.apple.finder` `ShowPathbar`

### `show_status_bar`

Shows the item count and free space at the bottom of windows.

- Value: true or false
- Writes: `com.apple.finder` `ShowStatusBar`

### `write_ds_store_on_network`

Leaves .DS_Store files in folders on network shares.

- Value: true or false
- Writes: `com.apple.desktopservices` `DSDontWriteNetworkStores`

### `write_ds_store_on_usb`

Leaves .DS_Store files in folders on USB drives.

- Value: true or false
- Writes: `com.apple.desktopservices` `DSDontWriteUSBStores`

## `[desktop]`

The desktop and Stage Manager. System Settings, Desktop & Dock, and Finder's settings.

### `show_hard_drives`

Shows this Mac's disks on the desktop.

- Value: true or false
- Writes: `com.apple.finder` `ShowHardDrivesOnDesktop`

### `show_external_drives`

Shows external disks on the desktop.

- Value: true or false
- Writes: `com.apple.finder` `ShowExternalHardDrivesOnDesktop`

### `show_removable_media`

Shows CDs, DVDs and iPods on the desktop.

- Value: true or false
- Writes: `com.apple.finder` `ShowRemovableMediaOnDesktop`

### `show_icons`

Shows the files on the desktop.

- Value: true or false
- Writes: `com.apple.WindowManager` `StandardHideDesktopIcons`

### `show_widgets`

Shows widgets on the desktop.

- Value: true or false
- Writes: `com.apple.WindowManager` `StandardHideWidgets`

### `click_to_show`

Clicking the wallpaper moves every window aside to show the desktop.

- Value: true or false
- Writes: `com.apple.WindowManager` `EnableStandardClickToShowDesktop`

### `stage_manager`

Turns Stage Manager on.

- Value: true or false
- Writes: `com.apple.WindowManager` `GloballyEnabled`

## `[dock]`

When the Dock shows and what's in it. System Settings, Desktop & Dock.

### `show`

When the Dock shows: always, when the pointer reaches it, or never.

- Value: "always", "auto_hide" or "never"
- Writes: `com.apple.dock` `autohide`, `com.apple.dock` `autohide-delay`, `com.apple.dock` `autohide-time-modifier`

### `pinned_apps`

The apps kept in the Dock, by their full paths. An empty list keeps none.

- Value: a list of apps' full paths, such as "/Applications/Safari.app"
- Writes: `com.apple.dock` `persistent-apps`

### `pinned_folders`

The folders kept in the Dock, by their full paths. An empty list keeps none.

- Value: a list of folders' full paths, such as "/Users/you/Downloads"
- Writes: `com.apple.dock` `persistent-others`

## `[screen_capture]`

Where macOS's own screenshots go. The Screenshot app's Options menu.

### `folder`

The folder screenshots are saved in, by its full path.

- Value: a folder's full path, starting with /
- Writes: `com.apple.screencapture` `location`

### `save_to`

Whether a screenshot is saved as a file, put on the clipboard, or opened in Preview.

- Value: "file", "clipboard" or "preview"
- Writes: `com.apple.screencapture` `target`

## `[siri]`

Siri. System Settings, Apple Intelligence & Siri.

### `enabled`

Turns Siri on. Off also stops it listening and takes it out of the menu bar.

- Value: true or false
- Writes: `com.apple.assistant.support` `Assistant Enabled`, `com.apple.Siri` `VoiceTriggerUserEnabled`, `com.apple.Siri` `StatusMenuVisible`

### `listen`

Siri listens for "Hey Siri".

- Value: true or false
- Writes: `com.apple.Siri` `VoiceTriggerUserEnabled`

### `show_in_menu_bar`

Shows Siri in the menu bar.

- Value: true or false
- Writes: `com.apple.Siri` `StatusMenuVisible`

## `[game_center]`

Game Center. System Settings, Game Center.

### `enabled`

Signs in to Game Center.

- Value: true or false
- Writes: `com.apple.gamed` `GKOptedOutOfGameCenter`

## `[power.battery]` and `[power.charger]`

The power settings, with one table for each power source. Each table takes the same settings. System Settings, Battery, Options.

### `dim_screen`

Dims the screen a little.

- Value: true or false
- Writes: `pmset` `lessbright`

### `dim_before_sleep`

Dims the screen before it turns off.

- Value: true or false
- Writes: `pmset` `halfdim`

### `screen_off_min`

Minutes without use before the screen turns off, 0 for never.

- Value: a whole number of minutes, 0 or more
- Writes: `pmset` `displaysleep`

### `sleep_min`

Minutes without use before the Mac sleeps, 0 for never.

- Value: a whole number of minutes, 0 or more
- Writes: `pmset` `sleep`

### `disk_sleep_min`

Minutes without use before the disks sleep, 0 for never.

- Value: a whole number of minutes, 0 or more
- Writes: `pmset` `disksleep`

### `wake_for_network`

Wakes the Mac when someone reaches it over the network.

- Value: true or false
- Writes: `pmset` `womp`

### `power_nap`

Lets the Mac check for mail and updates while it sleeps.

- Value: true or false
- Writes: `pmset` `powernap`

### `low_power_mode`

Uses less energy, at the cost of speed.

- Value: true or false
- Writes: `pmset` `lowpowermode`
