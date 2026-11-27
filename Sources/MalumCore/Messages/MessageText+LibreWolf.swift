/// The words for what's wrong in the add-ons, bookmarks, search engines and filters of
/// `apps/librewolf.toml`.
extension MessageText {
    /// What an add-on's ID looks like.
    static let addonID: MessageText =
        "an add-on's ID, such as \"uBlock0@raymondhill.net\" or \"{73a6fe31-595d-460b-a920-fcc0f8843232}\""

    /// What a search engine takes.
    static let searchEngine = MessageText(
        "a web address with %s for what you search, or a table of that address and an optional keyword, such as "
            + "{ address = \"https://www.startpage.com/search?q=%s\", keyword = \"@sp\" }")

    /// What a group of uBlock Origin's filters takes.
    static let filters: MessageText = "a filter, or a list of them"

    /// The add-on at `path`, written dotted, isn't named as in its addons.mozilla.org address.
    static func addonName(_ path: String) -> MessageText {
        "\(path) should be the add-on's name in its addons.mozilla.org address, such as ublock-origin"
    }
}
