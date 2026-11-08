import Foundation
import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct LocalFileSystemTests {
    @Test func listsAFolderAndMakesAFileExecutable() throws {
        let files = LocalFileSystem()
        let folder = NSTemporaryDirectory() + "malum-tests-\(UUID().uuidString)"
        defer { try? files.remove(folder) }
        try files.createDirectory(folder + "/inner")
        try files.write("#!/bin/sh\n", to: folder + "/tool")
        #expect(try files.contents(of: folder).sorted() == ["inner", "tool"])
        #expect(!files.isExecutable(folder + "/tool"))
        try files.makeExecutable(folder + "/tool")
        #expect(files.isExecutable(folder + "/tool"))
    }

    @Test func neverWritesATOMLFile() {
        let path = NSTemporaryDirectory() + "malum-tests-\(UUID().uuidString).TOML"
        #expect(throws: FileSystemError.userFile(path: path)) { try LocalFileSystem().write("", to: path) }
        #expect(LocalFileSystem().item(at: path) == nil)
    }

    @Test func neverCopiesOntoATOMLFile() throws {
        let files = LocalFileSystem()
        let folder = try Self.folder(holding: "plain")
        defer { try? files.remove(folder) }
        let toml = folder + "/packages.toml"
        #expect(throws: FileSystemError.userFile(path: toml)) { try files.copy(folder + "/plain", to: toml) }
        #expect(files.item(at: toml) == nil)
    }

    @Test func neverLinksATOMLFile() throws {
        let files = LocalFileSystem()
        let folder = try Self.folder(holding: "plain")
        defer { try? files.remove(folder) }
        let toml = folder + "/packages.toml"
        #expect(throws: FileSystemError.userFile(path: toml)) { try files.link(toml, to: folder + "/plain") }
        #expect(files.item(at: toml) == nil)
    }

    @Test func neverSwapsATOMLFileOnEitherSide() throws {
        let files = LocalFileSystem()
        let folder = try Self.folder(holding: "plain")
        defer { try? files.remove(folder) }
        let toml = folder + "/packages.toml"
        try Data("user = true\n".utf8).write(to: URL(fileURLWithPath: toml))
        #expect(throws: FileSystemError.userFile(path: toml)) { try files.exchange(toml, folder + "/plain") }
        #expect(throws: FileSystemError.userFile(path: toml)) { try files.exchange(folder + "/plain", toml) }
        #expect(try files.read(toml) == "user = true\n")
    }

    @Test func neverReplacesATOMLFile() throws {
        let files = LocalFileSystem()
        let folder = try Self.folder(holding: "plain")
        defer { try? files.remove(folder) }
        let toml = folder + "/packages.toml"
        try Data("user = true\n".utf8).write(to: URL(fileURLWithPath: toml))
        #expect(throws: FileSystemError.userFile(path: toml)) { try files.replace(toml, with: folder + "/plain") }
        #expect(try files.read(toml) == "user = true\n")
        #expect(try files.read(folder + "/plain") == "staged\n")
    }

    @Test func listingAMissingFolderIsAnError() {
        #expect(throws: FileSystemError.self) { try LocalFileSystem().contents(of: "/nonexistent-malum-folder") }
    }

    /// A new temporary folder with a file called `name` in it.
    private static func folder(holding name: String) throws -> String {
        let files = LocalFileSystem()
        let folder = NSTemporaryDirectory() + "malum-tests-\(UUID().uuidString)"
        try files.createDirectory(folder)
        try files.write("staged\n", to: folder + "/" + name)
        return folder
    }
}
