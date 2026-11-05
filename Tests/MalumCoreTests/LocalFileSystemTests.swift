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

    @Test func listingAMissingFolderIsAnError() {
        #expect(throws: FileSystemError.self) { try LocalFileSystem().contents(of: "/nonexistent-malum-folder") }
    }
}
