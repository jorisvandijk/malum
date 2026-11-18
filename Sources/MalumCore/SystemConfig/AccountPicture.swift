import Foundation

/// Makes the user's picture the Apple Account's picture when `apple_account_picture` in
/// `malum.toml` is set, instead of the one picked when the Mac was set up. macOS keeps a copy of
/// the Apple Account's picture, which can be any shape; its middle square becomes the user's
/// picture, kept in the state folder under a name that changes with the picture.
@MainActor
struct AccountPicture {
    /// The setting in `[system_config]` that switches it on.
    nonisolated static let key = "apple_account_picture"
    /// Where macOS lists the Apple Accounts signed in, under the home folder.
    private static let accountsList = "Library/Preferences/MobileMeAccounts.plist"
    /// The list of accounts in `accountsList`, the one in use first.
    private static let accountsKey = "Accounts"
    /// The id of an account in `accountsList`.
    private static let accountIDKey = "AccountUUID"
    /// Where macOS keeps the Apple Account's picture, under the home folder, before the account's id.
    private static let cachedPicturePrefix = "Library/Caches/AAProfilePicture_"
    /// The start of the user's picture's name in the state folder, before its fingerprint.
    private static let picturePrefix = "account-picture-"
    /// The extension of the picture files.
    private static let pictureExtension = "png"

    /// The disk.
    private let files: any FileSystem
    /// Where the home folder is.
    private let paths: Paths
    /// Runs `dscl`.
    private let runner: any CommandRunner
    /// Gets root.
    private let sudo: SudoSession
    /// Where the user's picture is kept.
    private let state: StateFolder
    /// Cuts the square out of the Apple Account's picture.
    private let pictures: any SquarePictures
    /// The user whose picture it is.
    private let user: String

    /// Creates the part, which sets the picture of `user` with `runner` through `sudo`, and keeps it in `state`.
    init(
        files: any FileSystem, paths: Paths, runner: any CommandRunner, sudo: SudoSession, state: StateFolder,
        pictures: any SquarePictures, user: String
    ) {
        self.files = files
        self.paths = paths
        self.runner = runner
        self.sudo = sudo
        self.state = state
        self.pictures = pictures
        self.user = user
    }

    /// Makes the user's picture the Apple Account's picture when `settings` switches it on and it
    /// isn't yet. Says whether it worked.
    func set(_ settings: ConfigTable, report: (Message) -> Void) async -> Bool {
        guard case .boolean(true) = settings[Self.key] else { return true }
        guard let source = cachedPicture() else {
            report(.noAppleAccountPicture)
            return true
        }
        let square: Data
        do {
            square = try pictures.squarePNG(of: source)
        } catch {
            report(.failed(.setAccountPicture, error))
            return false
        }
        let picture = state.path(of: "\(Self.picturePrefix)\(Fingerprint.of(square)).\(Self.pictureExtension)")
        let current = await currentPicture()
        guard current != picture || files.item(at: picture) == nil else { return true }
        do {
            try files.write(square, to: picture)
        } catch {
            report(.failed(.setAccountPicture, error))
            return false
        }
        guard await change(to: picture, from: current, report: report) else { return false }
        if let current, isOurs(current), current != picture {
            try? files.remove(current)  // A leftover old picture is harmless.
        }
        report(.accountPictureSet)
        return true
    }

    /// The path of macOS's copy of the Apple Account's picture, or nil when no account is signed
    /// in or macOS hasn't got its picture.
    private func cachedPicture() -> String? {
        let list = "\(paths.home)/\(Self.accountsList)"
        guard
            let data = try? files.data(at: list),  // No list: no account, reported.
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil),  // Nor a bad one.
            let accounts = (plist as? [String: Any])?[Self.accountsKey] as? [[String: Any]],
            let account = accounts.first?[Self.accountIDKey] as? String
        else { return nil }
        let picture = "\(paths.home)/\(Self.cachedPicturePrefix)\(account).\(Self.pictureExtension)"
        return files.item(at: picture) == nil ? nil : picture
    }

    /// The path of the user's picture now, or nil when there's none.
    private func currentPicture() async -> String? {
        let result = await runner.run(Dscl.readPicture(of: user))
        return result.succeeded ? Dscl.picture(in: result.output) : nil
    }

    /// Whether `path` is a picture Malum kept in the state folder.
    private func isOurs(_ path: String) -> Bool {
        path.hasPrefix(state.path(of: Self.picturePrefix))
    }

    /// Makes `picture` the user's picture as root, removing the copy macOS keeps of the picture
    /// `current` when that one isn't Malum's. Says whether it worked.
    private func change(to picture: String, from current: String?, report: (Message) -> Void) async -> Bool {
        guard await sudo.authorize(for: .setAccountPicture, report: report) else { return false }
        let replacesMacOSPicture = current.map { !isOurs($0) } ?? true
        var commands = [Dscl.setPicture(of: user, to: picture)]
        if replacesMacOSPicture { commands.append(Dscl.removePhoto(of: user)) }
        for command in commands {
            let result = await runner.run(Sudo.asRoot(command))
            guard result.succeeded else {
                report(.accountPictureNotSet(reason: result.reason))
                return false
            }
        }
        return true
    }
}
