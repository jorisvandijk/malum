// swiftlint:disable no_magic_numbers
// Lookup tables: each row names the values macOS stores a choice as.

/// The tables about Finder, the desktop, the Dock and screenshots.
extension MacOSCatalog {
    /// The domains these tables write to, besides the global one.
    private enum Domain {
        /// Finder.
        static let finder = "com.apple.finder"
        /// The files Finder keeps in folders it shows.
        static let desktopServices = "com.apple.desktopservices"
        /// The Dock.
        static let dock = "com.apple.dock"
        /// Screenshots.
        static let screenCapture = "com.apple.screencapture"
    }

    /// The seconds the Dock waits before it slides in, set so long that it never does.
    private static let neverDelay = ConfigValue.float(1000)

    /// `[finder]`.
    static let finder = CatalogTable(
        name: "finder", about: "Finder's windows and files. Finder, Settings, and the View menu.",
        settings: [
            CatalogSetting(
                "show_extensions", "Shows every file's extension.", .flag, [.global("AppleShowAllExtensions")]),
            CatalogSetting(
                "warn_on_extension_change", "Asks before a file's extension changes.", .flag,
                [.domain(Domain.finder, "FXEnableExtensionChangeWarning")]),
            CatalogSetting(
                "search_scope", "Where a search in a Finder window looks.",
                .choice([
                    .word("this_mac", .string("SCev")), .word("current_folder", .string("SCcf")),
                    .word("previous", .string("SCsp")),
                ]),
                [.domain(Domain.finder, "FXDefaultSearchScope")]),
            CatalogSetting(
                "view", "How new Finder windows show their files.",
                .choice([
                    .word("icons", .string("icnv")), .word("list", .string("Nlsv")), .word("columns", .string("clmv")),
                    .word("gallery", .string("glyv")),
                ]),
                [.domain(Domain.finder, "FXPreferredViewStyle")]),
            CatalogSetting(
                "new_window", "The folder a new Finder window opens.",
                .choice([
                    .word("home", .string("PfHm")), .word("desktop", .string("PfDe")),
                    .word("documents", .string("PfDo")), .word("computer", .string("PfCm")),
                ]),
                [.domain(Domain.finder, "NewWindowTarget")]),
            CatalogSetting(
                "empty_old_trash", "Removes items from the Trash after 30 days.", .flag,
                [.domain(Domain.finder, "FXRemoveOldTrashItems")]),
            CatalogSetting(
                "quit_menu_item", "Adds Quit Finder to Finder's menu.", .flag,
                [.domain(Domain.finder, "QuitMenuItem")]),
            CatalogSetting(
                "show_path_bar", "Shows the folder path at the bottom of windows.", .flag,
                [.domain(Domain.finder, "ShowPathbar")]),
            CatalogSetting(
                "show_status_bar", "Shows the item count and free space at the bottom of windows.", .flag,
                [.domain(Domain.finder, "ShowStatusBar")]),
            CatalogSetting(
                "write_ds_store_on_network", "Leaves .DS_Store files in folders on network shares.", .invertedFlag,
                [.domain(Domain.desktopServices, "DSDontWriteNetworkStores")]),
            CatalogSetting(
                "write_ds_store_on_usb", "Leaves .DS_Store files in folders on USB drives.", .invertedFlag,
                [.domain(Domain.desktopServices, "DSDontWriteUSBStores")]),
        ])

    /// `[desktop]`.
    static let desktop = CatalogTable(
        name: "desktop",
        about: "The desktop and Stage Manager. System Settings, Desktop & Dock, and Finder's settings.",
        settings: [
            CatalogSetting(
                "show_hard_drives", "Shows this Mac's disks on the desktop.", .flag,
                [.domain(Domain.finder, "ShowHardDrivesOnDesktop")]),
            CatalogSetting(
                "show_external_drives", "Shows external disks on the desktop.", .flag,
                [.domain(Domain.finder, "ShowExternalHardDrivesOnDesktop")]),
            CatalogSetting(
                "show_removable_media", "Shows CDs, DVDs and iPods on the desktop.", .flag,
                [.domain(Domain.finder, "ShowRemovableMediaOnDesktop")]),
            CatalogSetting(
                "show_icons", "Shows the files on the desktop.", .invertedFlag,
                [.domain(windowManager, "StandardHideDesktopIcons")]),
            CatalogSetting(
                "show_widgets", "Shows widgets on the desktop.", .invertedFlag,
                [.domain(windowManager, "StandardHideWidgets")]),
            CatalogSetting(
                "click_to_show", "Clicking the wallpaper moves every window aside to show the desktop.", .flag,
                [.domain(windowManager, "EnableStandardClickToShowDesktop")]),
            CatalogSetting(
                "stage_manager", "Turns Stage Manager on.", .flag, [.domain(windowManager, "GloballyEnabled")]),
        ])

    /// `[dock]`.
    static let dock = CatalogTable(
        name: "dock", about: "When the Dock shows and what's in it. System Settings, Desktop & Dock.",
        settings: [
            CatalogSetting(
                "show", "When the Dock shows: always, when the pointer reaches it, or never.",
                .choice([
                    CatalogChoice("always", [.set(.boolean(false)), .remove, .remove]),
                    CatalogChoice("auto_hide", [.set(.boolean(true)), .remove, .remove]),
                    CatalogChoice("never", [.set(.boolean(true)), .set(neverDelay), .set(.float(0))]),
                ]),
                [
                    .domain(Domain.dock, "autohide"), .domain(Domain.dock, "autohide-delay"),
                    .domain(Domain.dock, "autohide-time-modifier"),
                ]),
            CatalogSetting(
                "pinned_apps", "The apps kept in the Dock, by their full paths. An empty list keeps none.",
                .list(.dockApps), [.domain(Domain.dock, "persistent-apps")]),
            CatalogSetting(
                "pinned_folders", "The folders kept in the Dock, by their full paths. An empty list keeps none.",
                .list(.dockFolders), [.domain(Domain.dock, "persistent-others")]),
        ])

    /// `[screen_capture]`.
    static let screenCapture = CatalogTable(
        name: "screen_capture", about: "Where macOS's own screenshots go. The Screenshot app's Options menu.",
        settings: [
            CatalogSetting(
                "folder", "The folder screenshots are saved in, by its full path.", .folder,
                [.domain(Domain.screenCapture, "location")]),
            CatalogSetting(
                "save_to", "Whether a screenshot is saved as a file, put on the clipboard, or opened in Preview.",
                .choice([
                    .word("file", .string("file")), .word("clipboard", .string("clipboard")),
                    .word("preview", .string("preview")),
                ]),
                [.domain(Domain.screenCapture, "target")]),
        ])
}
// swiftlint:enable no_magic_numbers
