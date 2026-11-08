/// One kind of thing system config installs, such as Homebrew formulae or App Store apps: how to
/// tell what's installed, how to install and uninstall one, and where the record keeps it.
/// `ManagedSync` does the rest, the same for every kind.
@MainActor
protocol Installer {
    /// One thing of this kind, as `packages.toml` lists it.
    associatedtype Item: Sendable

    /// The kind as messages name it, such as `Homebrew cask`.
    var label: MessageText { get }
    /// The kind in the plural, such as `Homebrew casks`.
    var plural: MessageText { get }
    /// What tells two items apart, such as the App Store ID. It's the name unless the kind says otherwise.
    func key(of item: Item) -> String
    /// The item's name in `packages.toml`.
    func name(of item: Item) -> String
    /// The item as the installing and uninstalling messages show it.
    func shown(_ item: Item) -> String
    /// A check for whether an item is installed, or nil, after reporting why, when that can't be told.
    func installed(report: (Message) -> Void) async -> ((Item) -> Bool)?
    /// Gets ready to change what's installed, such as by asking for the password. Says whether it worked.
    func prepare(installing: Bool, removing: Bool, report: (Message) -> Void) async -> Bool
    /// Installs one item.
    func install(_ item: Item) async -> CommandResult
    /// Uninstalls one item.
    func uninstall(_ item: Item) async -> Uninstalled
    /// Adds `item` to `record`, or takes it out when it's no longer `managed`.
    func record(_ item: Item, managed: Bool, in record: inout InstalledRecord)
}

extension Installer {
    /// The name, unless the kind tells items apart by something else.
    func key(of item: Item) -> String { name(of: item) }

    /// The name, unless the kind shows more.
    func shown(_ item: Item) -> String { name(of: item) }

    /// Nothing to get ready, unless the kind needs it.
    func prepare(installing: Bool, removing: Bool, report: (Message) -> Void) async -> Bool { true }
}

/// What uninstalling one item did.
enum Uninstalled: Equatable {
    /// It's gone.
    case done
    /// Other installed things still need it, so it stays.
    case needed
    /// It failed, for this reason.
    case failed(reason: String)
}
