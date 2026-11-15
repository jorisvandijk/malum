import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct TerminalLaunchTests {
    private let malum = "/Users/test/Applications/Malum.app/Contents/MacOS/malum"

    @Test func namedTerminalRunsTheCommandThenKeepsAShell() {
        let launch = TerminalLaunch(
            settings: ["terminal": .string("net.kovidgoyal.kitty")], executable: malum, command: ["run"],
            shell: "/bin/zsh")
        #expect(launch?.bundleID == "net.kovidgoyal.kitty")
        #expect(launch?.arguments == ["-e", "/bin/zsh", "-l", "-c", "\(malum) run; exec /bin/zsh -l"])
    }

    @Test func pathWithSpacesIsQuoted() {
        let launch = TerminalLaunch(
            settings: ["terminal": .string("net.kovidgoyal.kitty")], executable: "/My Apps/malum", command: ["log"],
            shell: "/bin/zsh")
        #expect(launch?.arguments.last == "'/My Apps/malum' log; exec /bin/zsh -l")
    }

    @Test func noTerminalLeavesThePopup() {
        #expect(TerminalLaunch(settings: [:], executable: malum, command: ["run"], shell: "/bin/zsh") == nil)
        #expect(TerminalLaunch(settings: nil, executable: malum, command: ["run"], shell: "/bin/zsh") == nil)
        #expect(
            TerminalLaunch(settings: ["terminal": .string("")], executable: malum, command: ["run"], shell: "/bin/zsh")
                == nil)
    }
}
