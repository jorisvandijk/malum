import Foundation

/// Sets `[computer]` in `macos.toml`: this Mac's name and whether it plays a sound when it starts
/// up, as root through the run's one password prompt. A key taken out of the file leaves the
/// setting as it is.
@MainActor
struct ComputerSettings {
    /// The table of this Mac's own settings.
    static let table = "computer"
    /// The key that names this Mac.
    static let hostnameKey = "hostname"
    /// The key that says whether the Mac plays a sound when it starts up.
    static let bootSoundKey = "boot_sound"
    /// The longest name the local network takes.
    private static let longestHostname = 63

    /// What `[computer]` sets.
    struct Wanted: Equatable {
        /// The name for all three of the Mac's names, or nil to leave them.
        var hostname: String?
        /// Whether the startup sound plays, or nil to leave it.
        var bootSound: Bool?
    }

    /// Runs `scutil` and `nvram`.
    private let runner: any CommandRunner
    /// Gets root.
    private let sudo: SudoSession

    /// Creates the part, which runs its commands with `runner`, as root through `sudo`.
    init(runner: any CommandRunner, sudo: SudoSession) {
        self.runner = runner
        self.sudo = sudo
    }

    /// The settings in `[computer]`, adding a problem to `reader` for each one that's wrong.
    static func read(_ reader: inout TableReader) -> Wanted {
        let computer = reader.table(reader.document, table, at: [])
        reader.unknownKeys(computer, at: [table], known: [hostnameKey, bootSoundKey])
        var wanted = Wanted()
        if let value = computer[hostnameKey] {
            wanted.hostname = hostname(value, &reader)
        }
        if let value = computer[bootSoundKey] {
            guard case .boolean(let on) = value else {
                reader.expect([table, bootSoundKey], SettingKind.boolean)
                return wanted
            }
            wanted.bootSound = on
        }
        return wanted
    }

    /// Sets each setting in `wanted` that doesn't hold its value yet. Says whether everything worked.
    func write(_ wanted: Wanted, report: (Message) -> Void) async -> Bool {
        var succeeded = true
        if let hostname = wanted.hostname {
            for name in Scutil.Name.allCases {
                succeeded = await set(name, to: hostname, report) && succeeded
            }
        }
        if let bootSound = wanted.bootSound {
            succeeded = await setBootSound(bootSound, report) && succeeded
        }
        return succeeded
    }

    /// The name in `value`, or nil with a problem added to `reader` when it isn't one the local
    /// network takes: letters, digits and dashes, not starting or ending with a dash.
    private static func hostname(_ value: ConfigValue, _ reader: inout TableReader) -> String? {
        let path = [table, hostnameKey]
        guard case .string(let name) = value else {
            reader.expect(path, SettingKind.string)
            return nil
        }
        let allowed = name.allSatisfy { ($0.isASCII && ($0.isLetter || $0.isNumber)) || $0 == "-" }
        let fits = !name.isEmpty && name.count <= longestHostname
        guard allowed && fits && !name.hasPrefix("-") && !name.hasSuffix("-") else {
            reader.add(.error, at: path, .notHostname(TableReader.dotted(path)))
            return nil
        }
        return name
    }

    /// Sets the Mac's name `name` to `value` when it's something else now. Says whether it worked.
    private func set(_ name: Scutil.Name, to value: String, _ report: (Message) -> Void) async -> Bool {
        let now = await runner.run(Scutil.get(name))
        // A name that was never set fails to read, and is set like any other.
        guard !now.succeeded || now.output.trimmingCharacters(in: .whitespacesAndNewlines) != value else {
            return true
        }
        guard await asRoot(Scutil.set(name, to: value), setting: "\(name.rawValue)", report) else { return false }
        report(.hostnameSet(name.rawValue, to: value))
        return true
    }

    /// Lets the startup sound play when `on` is set, and mutes it when not, unless it already does.
    /// Says whether it worked.
    private func setBootSound(_ on: Bool, _ report: (Message) -> Void) async -> Bool {
        let now = await runner.run(Nvram.readStartupMute)
        // A Mac that never muted it has no such variable, so reading it fails and the sound plays.
        let muted = now.succeeded && Nvram.isMuted(now.output)
        guard muted == on else { return true }
        guard await asRoot(Nvram.setStartupMute(!on), setting: .bootSound, report) else { return false }
        report(.bootSoundSet(on))
        return true
    }

    /// Runs `command`, which changes `setting`, as root, asking for the password the first time.
    /// Says whether it worked.
    private func asRoot(_ command: Command, setting: MessageText, _ report: (Message) -> Void) async -> Bool {
        guard await sudo.authorize(for: .changeComputer, report: report) else { return false }
        let result = await runner.run(Sudo.asRoot(command))
        if !result.succeeded { report(.computerNotSet(setting, reason: result.reason)) }
        return result.succeeded
    }
}
