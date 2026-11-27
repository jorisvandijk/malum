import Testing

@testable import MalumCore

/// Checks that cover every choice, power setting and raw key the catalog knows.
extension MacOSCatalogTests {
    @Test func everyWordOfEveryChoiceIsAccepted() {
        for table in MacOSCatalog.tables {
            for setting in table.settings {
                guard case .choice(let choices) = setting.value else { continue }
                for choice in choices {
                    let (preferences, problems) = read("[\(table.name)]\n\(setting.name) = \"\(choice.word)\"\n")
                    let name = "\(table.name).\(setting.name) = \(choice.word)"
                    #expect(problems.isEmpty, "\(name)")
                    #expect(preferences.count == choice.writes.filter { $0 != .leave }.count, "\(name)")
                }
            }
        }
    }

    @Test func rawAndCuratedSettingWritingTheSameValueIsOnlyTheRawWarning() {
        let (preferences, problems) = read(
            "[pointer]\nnatural_scrolling = false\n[preferences.NSGlobalDomain]\n\"com.apple.swipescrolldirection\" = false\n"
        )
        #expect(problems.map(\.level) == [.warn])
        #expect(preferences == ["NSGlobalDomain com.apple.swipescrolldirection = <false/>"])
    }

    @Test func everyPowerSettingWritesItsPmsetName() {
        let flags = PowerSetting.all.filter { $0.kind == PowerSetting.flag }.map { "\($0.name) = true" }
        let minutes = PowerSetting.all.filter { $0.kind == PowerSetting.minutes }.map { "\($0.name) = 5" }
        let (wanted, problems) = MacOSSettings.read(
            "[power.battery]\n" + (flags + minutes).joined(separator: "\n") + "\n")
        #expect(problems.isEmpty)
        #expect(Set(wanted?.power[.battery]?.keys.map { $0 } ?? []) == Set(PowerSetting.all.map(\.pmset)))
    }
}
