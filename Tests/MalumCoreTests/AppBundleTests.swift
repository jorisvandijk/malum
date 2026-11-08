import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct AppBundleTests {
    @Test func executableInsideAppIsFound() {
        let path = "/Users/test/Applications/Malum.app/Contents/MacOS/Malum"
        #expect(AppBundle.executable(at: path) == path)
    }

    @Test func buildFolderIsNotAnApp() {
        #expect(AppBundle.executable(at: "/Users/test/git/malum/.build/debug/Malum") == nil)
    }

    @Test func appWithoutContentsIsNotAnApp() {
        #expect(AppBundle.executable(at: "/Users/test/Applications/Malum.app/MacOS/Malum") == nil)
    }
}
