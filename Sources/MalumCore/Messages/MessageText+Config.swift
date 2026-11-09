/// The words for what's wrong in one of Malum's TOML files in dots.
extension MessageText {
    /// The key at `path`, written dotted, should be `expected`, such as `SettingKind.string`.
    static func shouldBe(_ path: String, _ expected: some CustomStringConvertible) -> MessageText {
        "\(path) should be \(expected.description)"
    }

    /// No one reads the key at `path`, written dotted, which is a table or a setting.
    static func unknownKey(_ path: String, isTable: Bool) -> MessageText {
        let kind = isTable ? "table" : "setting"
        return "unknown \(kind) \(path)"
    }

    /// `malum.toml` has a table `key` that isn't a module's.
    static func unknownModule(_ key: String) -> MessageText {
        "unknown module \(key)"
    }

    /// `module` has settings in its table in `malum.toml` and in its own file too.
    static func settingsInTwoPlaces(_ module: String) -> MessageText {
        "\(module) has settings here and in \(Paths.moduleTOMLName(module)): keep them in one of the two"
    }

    /// `module`'s own file holds its switch, which only `malum.toml` holds.
    static func switchOutsideConfig(_ module: String) -> MessageText {
        "\(ConfigSchema.switchKey) goes in the [\(module)] table of \(Paths.configTOMLName), not here"
    }

    /// `malum.toml` has a setting `key` outside every module's table.
    static func outsideModule(_ key: String) -> MessageText {
        "\(key) isn't inside a module's table"
    }

    /// The name at `path`, written dotted, isn't safe as a file name: see `Paths.isPlainName`.
    static func notPlainName(_ path: String) -> MessageText {
        "\(path): the name can't be empty, start with a dot or hold /"
    }

    /// The name at `path`, written dotted, is already another entry's name.
    static func takenName(_ path: String) -> MessageText {
        "\(path): another entry already has this name"
    }

    /// The name at `path`, written dotted, of a `name value` line is empty or holds spaces.
    static func notLineName(_ path: String) -> MessageText {
        "\(path): the name can't be empty or hold spaces"
    }

    /// The Homebrew package at `path`, written dotted, starts with `-`, which `brew` would take as an option.
    static func notPackageName(_ path: String) -> MessageText {
        "\(path): a package name can't start with -"
    }

    /// The domain at `path`, written dotted, starts with `-`, which `defaults` would take as an option.
    static func notDomain(_ path: String) -> MessageText {
        "\(path): a preferences domain can't start with -"
    }

    /// The hosts entry at `path`, written dotted, has an empty name or address or one with spaces.
    static func notHostsEntry(_ path: String) -> MessageText {
        "\(path): a host name and its address can't be empty or hold spaces"
    }

    /// The bundle ID at `path`, written dotted, is empty or holds spaces.
    static func notBundleID(_ path: String) -> MessageText {
        "\(path): a bundle ID can't be empty or hold spaces"
    }

    /// The key at `path`, written dotted, is `name`, which isn't one of `Key`'s names.
    static func notKeyName(_ path: String, _ name: String) -> MessageText {
        "\(path): \(name) isn't a key name"
    }

    /// The table of shortcuts `table` names its modifiers in another order, and is written `spelling`.
    static func modifierOrder(_ table: String, _ spelling: String) -> MessageText {
        "\(table) should be written \(spelling)"
    }

    /// The remap at `path`, written dotted, remaps `name`, which is the hyper key.
    static func remapsHyperKey(_ path: String, _ name: String) -> MessageText {
        "\(path): \(name) is the hyper key, so it can't be remapped too"
    }

    /// The shortcut at `path`, written dotted, binds `name`, which no module offers.
    static func unknownAction(_ path: String, _ name: String) -> MessageText {
        "\(path): no module offers \(name)"
    }

    /// The shortcut at `path`, written dotted, is `hotkey`, which `module` claims for itself.
    static func hotkeyTaken(_ path: String, _ hotkey: String, _ module: String) -> MessageText {
        "\(path): \(hotkey) is taken by \(module)"
    }

    /// `first` and `second` both claim `thing`, which only one module can have; `first` keeps it.
    static func claimedTwice(_ thing: String, _ first: String, _ second: String) -> MessageText {
        "\(first) and \(second) both claim \(thing), so \(second) doesn't get it"
    }

    /// `module` has shortcuts but is switched off.
    static func moduleOff(_ module: String) -> MessageText {
        "\(module) is switched off, so its keys do nothing"
    }

    /// Shortcuts name apps, but no module that opens apps is there yet.
    static var noAppOpener: MessageText {
        "no module opens apps yet, so the keys bound to apps do nothing"
    }

    /// `file` couldn't be read, for `reason`.
    static func unreadable(_ file: String, _ reason: String) -> MessageText {
        "couldn't read \(file): \(reason)"
    }

    /// `malum.toml` couldn't be loaded because dots isn't known yet.
    static var noDotsYet: MessageText {
        "couldn't load \(Paths.configTOMLName): no dots folder yet, run \(Project.command) init"
    }

    /// `malum.toml` couldn't be loaded because there's nothing at `path`.
    static func configMissing(_ path: String) -> MessageText {
        "couldn't load \(private: path): it doesn't exist"
    }

    // MARK: - Should be

    /// What a value has to be to become a property list.
    static var plistValue: MessageText { "text, a number, true or false, or a list or table of them" }

    /// What a value in a JSON file has to be.
    static var jsonValue: MessageText { "text, a number, true or false, or a list of them" }

    /// What a value in a file of calls, such as `user_pref`, has to be.
    static var callValue: MessageText { "text, a number, or true or false" }

    /// What a value in a git style config file has to be.
    static var iniValue: MessageText { "text, a whole number, true or false, or a list of them" }

    /// What a value in a file of `name value` lines has to be.
    static var lineValue: MessageText { "text on one line, a number, true or false, or a list of them" }

    /// What a newsboat feed has to be.
    static var feedValue: MessageText { "an address without spaces, or a table with url and tags" }

    /// What a Homebrew package's kind has to be.
    static var homebrewKind: MessageText { "\"formula\" or \"cask\"" }

    /// What an App Store app's value has to be.
    static var appStoreID: MessageText { "the app's App Store ID, \(SettingKind.integer)" }

    /// What a release's `repo` has to be.
    static var repository: MessageText { "the repository, as \"owner/name\"" }

    /// What a key in `keyboard.toml` has to be.
    static var keyName: MessageText { "a key name, such as \"caps_lock\"" }

    /// What `hyper_key` has to be.
    static var hyperKeyName: MessageText {
        "one of \(Key.hyperKeys.map { Escaping.quoted($0.name, controls: .all) }.joined(separator: ", "))"
    }

    /// What a shortcut in `keyboard.toml` does.
    static var keyAction: MessageText { "an app's bundle ID or a module's action, such as \"launcher\"" }

    /// What a window manager's `frame` should be.
    static var screenFrame: MessageText {
        MessageText(ScreenFrame.allCases.map { "\"\($0.rawValue)\"" }.joined(separator: " or "))
    }

    /// What a float rule's `title` should be.
    static var titlePattern: MessageText { "a pattern for the window's title, such as \"^Picture-in-Picture$\"" }

    /// What a Samba server's host and user have to be.
    static var sambaText: MessageText { "text without spaces, such as \"nas.local\"" }

    /// What a Samba server's shares have to be.
    static var shareList: MessageText { "a list of one or more share names" }

    /// What the screenshots folder has to be.
    static var screenshotFolder: MessageText { "a folder, such as \"\(ScreenshotsConfig.defaultFolder)\"" }

    /// What the screenshots' quick colors have to be.
    static var screenshotColors: MessageText {
        "a list of 1 to \(ScreenshotsConfig.maxColors) colors as \"#rrggbb\", such as \"#ff3b30\""
    }

    /// What a list of VSCodium extensions has to be.
    static var extensionList: MessageText { "a list of extensions as \"publisher.name\"" }
}
