import Testing

@testable import MalumCore

/// The config style rules every real catalog keeps: macos.toml's and each app's.
extension CatalogTests {
    /// Every real catalog.
    private static var catalogs: [Catalog] {
        [MacOSCatalog.catalog] + AppConfigs.all.compactMap(\.catalog)
    }

    @Test func everySettingTakesAtLeastTwoValues() {
        for catalog in Self.catalogs {
            for table in catalog.tables {
                for setting in table.settings {
                    #expect((setting.value.choices ?? 2) >= 2, "\(catalog.file) \(table.name).\(setting.name)")
                }
            }
        }
    }

    @Test func everyChoiceWritesEachTarget() {
        for setting in Self.catalogs.flatMap(\.tables).flatMap(\.settings) {
            switch setting.value {
            case .choice(let choices):
                #expect(choices.allSatisfy { $0.writes.count == setting.targets.count }, "\(setting.name)")
                #expect(Set(choices.map(\.word)).count == choices.count, "\(setting.name)")
            case .combinedFlag(let on, let off):
                #expect(on.count == setting.targets.count && off.count == setting.targets.count, "\(setting.name)")
            default:
                #expect(!setting.targets.isEmpty, "\(setting.name)")
            }
        }
    }

    @Test func namesAreUniqueAndPlain() {
        for catalog in Self.catalogs {
            let tables = catalog.tables.map(\.name)
            #expect(Set(tables).count == tables.count, "\(catalog.file)")
            for table in catalog.tables {
                let names = table.settings.map(\.name)
                #expect(Set(names).count == names.count, "\(catalog.file) \(table.name)")
                #expect(
                    (names + table.path).allSatisfy { $0.allSatisfy { $0.isLowercase || $0.isNumber || $0 == "_" } },
                    "\(catalog.file) \(table.name)")
            }
        }
    }

    @Test func aPartOfATableIsOneLevelInsideATableOfTheCatalog() {
        for catalog in Self.catalogs {
            for table in catalog.tables where table.path.count > 1 {
                #expect(table.path.count == 2, "\(catalog.file) \(table.name)")
                #expect(catalog.topTables.contains(table.path.first ?? ""), "\(catalog.file) \(table.name)")
            }
        }
    }

    @Test func aNumberWithAUnitEndsInIt() {
        for setting in Self.catalogs.flatMap(\.tables).flatMap(\.settings) {
            guard case .number(let unit, _, _) = setting.value else { continue }
            #expect(setting.name.hasSuffix(unit.suffix), "\(setting.name)")
        }
    }

    @Test func anAppsCatalogReadsItsFileAndWritesItsDomain() {
        for app in AppConfigs.all {
            guard let catalog = app.catalog else { continue }
            #expect(catalog.file == Paths.appFile(named: app.name))
            let targets = catalog.tables.flatMap(\.settings).flatMap(\.targets) + catalog.always.map(\.target)
            for case .preference(let domain, let key) in targets {
                #expect(domain == app.domain, "\(app.name) \(key)")
            }
        }
    }
}
