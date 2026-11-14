/// Sets `[screen_lock]` in `macos.toml`: how soon the Mac asks for the password once the screen
/// goes black, such as when it dims, sleeps or shows the screensaver. Changing it takes the user's
/// own password, which `sysadminctl` asks for on the terminal. A key taken out of the file leaves
/// the setting as it is.
@MainActor
struct ScreenLockSettings {
    /// The table of the screen lock's settings.
    static let table = "screen_lock"
    /// The key that holds the seconds before the password is asked, 0 for right away.
    static let delayKey = "delay"

    /// Runs `sysadminctl`.
    private let runner: any CommandRunner
    /// Says whether there's a terminal to ask for the password in.
    private let sudo: SudoSession

    /// Creates the part, which runs `sysadminctl` with `runner` when `sudo` can ask.
    init(runner: any CommandRunner, sudo: SudoSession) {
        self.runner = runner
        self.sudo = sudo
    }

    /// The seconds in `[screen_lock]`, or nil when it sets none, adding a problem to `reader` when
    /// it's wrong.
    static func read(_ reader: inout TableReader) -> Int? {
        guard reader.document[table] != nil else { return nil }
        let lock = reader.table(reader.document, table, at: [])
        reader.unknownKeys(lock, at: [table], known: [delayKey])
        guard let value = lock[delayKey] else { return nil }
        guard case .integer(let seconds) = value, seconds >= 0 else {
            reader.expect([table, delayKey], MessageText.lockDelay)
            return nil
        }
        return seconds
    }

    /// Asks for the password `wanted` seconds after the screen goes black, when it doesn't yet.
    /// Says whether it worked.
    func set(_ wanted: Int?, report: (Message) -> Void) async -> Bool {
        guard let wanted else { return true }
        guard await current() != .after(wanted) else { return true }
        guard sudo.canAsk else {
            report(.passwordNeedsTerminal(for: .changeScreenLock))
            return false
        }
        report(.askingForPassword(for: .changeScreenLock))
        let result = await runner.run(Sysadminctl.setScreenLock(after: wanted))
        // sysadminctl doesn't always fail on a wrong password, so what it says now decides, when it says.
        let now = await current()
        guard result.succeeded, now == nil || now == .after(wanted) else {
            report(.screenLockNotSet)
            return false
        }
        report(.screenLockSet(after: wanted))
        return true
    }

    /// How soon the password is asked now, or nil when `sysadminctl` doesn't say.
    private func current() async -> Sysadminctl.ScreenLock? {
        let read = await runner.run(Sysadminctl.screenLockStatus)
        return Sysadminctl.screenLock(in: read.output + read.errors)
    }
}
