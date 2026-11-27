/// Reaching into nested tables by a path of keys.
extension ConfigTable {
    /// The value at `path`, or nil when there's none.
    func value(at path: [String]) -> ConfigValue? {
        guard let key = path.first else { return nil }
        guard path.count > 1 else { return self[key] }
        guard case .table(let inner)? = self[key] else { return nil }
        return inner.value(at: Array(path.dropFirst()))
    }

    /// Puts `value` at `path`, making the tables on the way, or removes what's there when it's nil.
    mutating func set(_ value: ConfigValue?, at path: [String]) {
        guard let key = path.first else { return }
        guard path.count > 1 else {
            self[key] = value
            return
        }
        var inner: ConfigTable
        if case .table(let existing)? = self[key] {
            inner = existing
        } else {
            guard value != nil else { return }
            inner = [:]
        }
        inner.set(value, at: Array(path.dropFirst()))
        self[key] = .table(inner)
    }
}
