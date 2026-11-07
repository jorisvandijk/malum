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

    /// `malum.toml` has a setting `key` outside every module's table.
    static func outsideModule(_ key: String) -> MessageText {
        "\(key) isn't inside a module's table"
    }

    /// The name at `path`, written dotted, isn't safe as a file name: see `Paths.isPlainName`.
    static func notPlainName(_ path: String) -> MessageText {
        "\(path): the name can't be empty, start with a dot or hold /"
    }

    /// The domain at `path`, written dotted, starts with `-`, which `defaults` would take as an option.
    static func notDomain(_ path: String) -> MessageText {
        "\(path): a preferences domain can't start with -"
    }

    /// The hosts entry at `path`, written dotted, has an empty name or address or one with spaces.
    static func notHostsEntry(_ path: String) -> MessageText {
        "\(path): a host name and its address can't be empty or hold spaces"
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
}
