import Foundation

/// Makes the picture `user_picture` in `malum.toml` names, from the `pictures` folder in dots, the
/// user's picture, the one on the login screen and in Users & Groups. Its middle square is kept in
/// the state folder under a name that changes with the picture, and stored in the account the way
/// System Settings does. Leaving the setting out leaves the picture as it is.
@MainActor
struct UserPicture {
    /// The setting in `[system_config]` that names the picture.
    nonisolated static let key = "user_picture"
    /// The start of the user's picture's name in the state folder, before its fingerprint.
    private static let picturePrefix = "user-picture-"
    /// The extension of the user's picture.
    private static let pictureExtension = "jpg"
    /// The file in the state folder that tells `dsimport` which picture to store.
    private static let importName = "user-picture.import"

    /// The disk.
    private let files: any FileSystem
    /// Where the `pictures` folder is.
    private let paths: Paths
    /// Runs `dscl` and `dsimport`.
    private let runner: any CommandRunner
    /// Gets root.
    private let sudo: SudoSession
    /// Where the user's picture is kept.
    private let state: StateFolder
    /// Cuts the square out of the picture.
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

    /// Makes the picture `settings` names, from the dots folder `dots`, the user's picture when it
    /// isn't yet. Says whether it worked.
    func set(_ settings: ConfigTable, dots: String, report: (Message) -> Void) async -> Bool {
        guard case .string(let name) = settings[Self.key] else { return true }
        let folder = paths.picturesFolder(in: dots)
        guard let file = DotsPicture.file(named: name, in: folder, on: files) else {
            report(.noUserPicture(name, in: folder))
            return false
        }
        let square: Data
        do {
            square = try pictures.squareJPEG(of: "\(folder)/\(file)")
        } catch {
            report(.failed(.setUserPicture, error))
            return false
        }
        let picture = state.path(of: "\(Self.picturePrefix)\(Fingerprint.of(square)).\(Self.pictureExtension)")
        let current = await currentPicture()
        guard current != picture || files.item(at: picture) == nil else { return true }
        do {
            try files.write(square, to: picture)
        } catch {
            report(.failed(.setUserPicture, error))
            return false
        }
        guard await change(to: picture, report: report) else { return false }
        if let current, isOurs(current), current != picture {
            try? files.remove(current)  // A leftover old picture is harmless.
        }
        report(.userPictureSet(file))
        return true
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

    /// Makes `picture` the user's picture as root, and the copy the account keeps, which wins over
    /// the path. Says whether it worked.
    private func change(to picture: String, report: (Message) -> Void) async -> Bool {
        guard await sudo.authorize(for: .setUserPicture, report: report) else { return false }
        let importFile = state.path(of: Self.importName)
        do {
            try files.write(Dsimport.photoFile(of: user, photo: picture), to: importFile)
        } catch {
            report(.failed(.setUserPicture, error))
            return false
        }
        defer { try? files.remove(importFile) }  // A leftover is harmless: the next change replaces it.
        let hasPhoto = await runner.run(Dscl.readPhoto(of: user)).succeeded
        var commands = [Dscl.setPicture(of: user, to: picture)]
        if hasPhoto { commands.append(Dscl.removePhoto(of: user)) }
        commands.append(Dsimport.importPhoto(from: importFile))
        for command in commands {
            let result = await runner.run(Sudo.asRoot(command))
            guard result.succeeded else {
                report(.userPictureNotSet(reason: result.reason))
                return false
            }
        }
        return true
    }
}
