extension Array {
    /// The values, or nil when one of them is nil, such as a list where one item can't be written.
    func allPresent<Wrapped>() -> [Wrapped]? where Element == Wrapped? {
        let present = compactMap(\.self)
        return present.count == count ? present : nil
    }
}
