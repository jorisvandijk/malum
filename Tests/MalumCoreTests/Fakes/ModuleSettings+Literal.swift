@testable import MalumCore

// MARK: - ExpressibleByDictionaryLiteral

/// Settings written as a table, with no file, so tests can pass `["size": .integer(1)]`.
extension ModuleSettings: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (String, ConfigValue)...) {
        self.init(table: ConfigTable(uniqueKeysWithValues: elements))
    }
}
