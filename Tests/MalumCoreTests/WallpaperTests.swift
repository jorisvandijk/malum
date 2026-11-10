import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
@MainActor
struct WallpaperTests {
    private static let folder = "/Users/test/dots/wallpapers"
    private static let dunes = "\(folder)/dunes.jpg"
    private let paths = Paths(home: "/Users/test")

    /// Sets the wallpaper `name` on a disk with `pictures`, and gives back whether it worked and
    /// what it said.
    private func set(
        _ name: ConfigValue?, pictures: [String] = [dunes], desktop: FakeDesktop
    ) -> (Bool, [Message]) {
        let files = FakeFileSystem(texts: Dictionary(uniqueKeysWithValues: pictures.map { ($0, "") }))
        var messages: [Message] = []
        let settings: ConfigTable = name.map { [Wallpaper.key: $0] } ?? [:]
        let succeeded = Wallpaper(files: files, paths: paths, desktop: desktop).set(
            settings, dots: "/Users/test/dots"
        ) { messages.append($0) }
        return (succeeded, messages)
    }

    @Test func nameWithoutExtensionShowsThePictureOnEveryScreen() {
        let desktop = FakeDesktop(shown: [nil, "/System/Library/Desktop Pictures/Sequoia.heic"])
        let (succeeded, messages) = set(.string("dunes"), desktop: desktop)
        #expect(succeeded)
        #expect(desktop.shown == [Self.dunes, Self.dunes])
        #expect(messages == [Message(.info, "set the wallpaper to dunes.jpg from wallpapers in dots")])
    }

    @Test func pictureAlreadyShownChangesNothing() {
        let desktop = FakeDesktop(shown: [Self.dunes])
        let (succeeded, messages) = set(.string("dunes.jpg"), desktop: desktop)
        #expect(succeeded)
        #expect(messages.isEmpty)
    }

    @Test func noSettingLeavesTheWallpaper() {
        let desktop = FakeDesktop(shown: [nil])
        let (succeeded, messages) = set(nil, desktop: desktop)
        #expect(succeeded)
        #expect(desktop.shown == [nil])
        #expect(messages.isEmpty)
    }

    @Test func missingPictureIsAnError() {
        let desktop = FakeDesktop()
        for name in ["beach", "../dunes.jpg"] {
            let (succeeded, messages) = set(.string(name), desktop: desktop)
            #expect(!succeeded)
            #expect(
                messages == [
                    Message(.error, "couldn't set the wallpaper: there's no picture called \(name) in \(Self.folder)")
                ])
        }
    }

    @Test func refusedPictureIsReported() {
        let desktop = FakeDesktop(failure: .unreadable(path: Self.dunes, reason: "not a picture"))
        let (succeeded, messages) = set(.string("dunes"), desktop: desktop)
        #expect(!succeeded)
        #expect(messages.count == 1)
        #expect(messages.first?.level == .error)
    }
}
