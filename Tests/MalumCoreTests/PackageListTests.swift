import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct PackageListTests {
    @Test func homebrewEntriesAreSortedByKind() {
        let reading = PackageList.read(
            """
            [homebrew]
            mole = "formula"
            bitwarden = "cask"
            "olets/tap/zsh-abbr" = "formula"
            """)
        #expect(
            reading.list == PackageList(homebrew: [.formula: ["mole", "olets/tap/zsh-abbr"], .cask: ["bitwarden"]]))
        #expect(reading.problems.isEmpty)
    }

    @Test func emptyFileListsNothing() {
        let reading = PackageList.read("")
        #expect(reading.list == PackageList())
        #expect(reading.problems.isEmpty)
    }

    @Test func wrongKindIsAnErrorWithItsLine() {
        let reading = PackageList.read("[homebrew]\nmole = \"formula\"\nkitty = \"app\"\nbat = 3\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "packages.toml line 3: homebrew.kitty should be \"formula\" or \"cask\""),
                Message(.error, "packages.toml line 4: homebrew.bat should be \"formula\" or \"cask\""),
            ])
    }

    @Test func homebrewThatIsntATableIsAnError() {
        let reading = PackageList.read("homebrew = \"bat\"\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [Message(.error, "packages.toml line 1: homebrew should be a table")])
    }

    @Test func unknownTableIsOnlyAWarning() {
        let reading = PackageList.read("[homebrew]\nbat = \"formula\"\n\n[mystery]\nanswer = 42\n")
        #expect(reading.list == PackageList(homebrew: [.formula: ["bat"]]))
        #expect(reading.problems.map(\.message) == [Message(.warn, "packages.toml line 4: unknown table mystery")])
    }

    @Test func appStoreAppsAreSortedByName() {
        let reading = PackageList.read("[app_store]\nxcode = 497799835\namphetamine = 937984704\n")
        #expect(
            reading.list
                == PackageList(appStore: [
                    AppStoreApp("amphetamine", id: 937_984_704), AppStoreApp("xcode", id: 497_799_835),
                ])
        )
        #expect(reading.problems.isEmpty)
    }

    @Test func appStoreIdThatIsntAWholeNumberIsAnError() {
        let reading = PackageList.read("[app_store]\nxcode = \"497799835\"\nbroken = 0\nfine = 1\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(
                    .error, "packages.toml line 2: app_store.xcode should be the app's App Store ID, a whole number"),
                Message(
                    .error, "packages.toml line 3: app_store.broken should be the app's App Store ID, a whole number"),
            ])
    }

    @Test func appStoreThatIsntATableIsAnError() {
        let reading = PackageList.read("app_store = 497799835\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [Message(.error, "packages.toml line 1: app_store should be a table")])
    }

    @Test func syntaxErrorGivesLineAndColumn() {
        let reading = PackageList.read("[homebrew]\nbat = \n")
        #expect(reading.list == nil)
        #expect(reading.problems.first?.line == 2)
        #expect(reading.problems.first?.file == "packages.toml")
    }

    @Test func releasesAreReadWithTheirRepoAndAsset() {
        let reading = PackageList.read(
            """
            [release.pagefind]
            repo = "CloudCannon/pagefind"

            [release.mpv]
            repo = "mpv-player/mpv"
            asset = "mpv-*-arm.zip"
            """)
        #expect(
            reading.list
                == PackageList(releases: [
                    ReleaseEntry("mpv", repo: "mpv-player/mpv", asset: "mpv-*-arm.zip"),
                    ReleaseEntry("pagefind", repo: "CloudCannon/pagefind"),
                ]))
        #expect(reading.problems.isEmpty)
    }

    @Test func badReleasesAreErrorsWithTheirLines() {
        let reading = PackageList.read(
            """
            [release.mpv]
            repo = "mpv"

            [release.tool]
            repo = "a/tool"
            asset = 3
            colour = "red"
            """)
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "packages.toml line 2: release.mpv.repo should be the repository, as \"owner/name\""),
                Message(.error, "packages.toml line 6: release.tool.asset should be text in quotes"),
                Message(.warn, "packages.toml line 7: unknown setting release.tool.colour"),
            ])
    }

    @Test func releaseNamesCantLeaveTheFolder() {
        let reading = PackageList.read(
            """
            [release."sub/tool"]
            repo = "a/tool"

            [release."../../bin/sh"]
            repo = "a/tool"
            """)
        #expect(reading.list == nil)
        let rule = "the name can't be empty, start with a dot or hold /"
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "packages.toml line 1: release.\"sub/tool\": \(rule)"),
                Message(.error, "release.\"../../bin/sh\": \(rule)"),
            ])
    }

    @Test func packageNamesLikeAFlagAreRefused() {
        let reading = PackageList.read("[homebrew]\n\"--force\" = \"formula\"\n")
        #expect(reading.list == nil)
        #expect(
            reading.problems.map(\.message) == [
                Message(.error, "packages.toml line 2: homebrew.--force: a package name can't start with -")
            ])
    }
}
