/// Property lists, the format `defaults` takes an app's preferences in, one value at a time.
enum PlistText {
    /// `value` as a property list document, or nil when it isn't text, a number, true or false,
    /// or a list or table of them.
    static func document(_ value: ConfigValue) -> String? {
        element(value).map { element in
            """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">\(element)</plist>
            """
        }
    }

    /// `value` as one property list element, or nil when it can't be one.
    private static func element(_ value: ConfigValue) -> String? {
        switch value {
        case .string(let text):
            "<string>\(Escaping.xml(text))</string>"
        case .integer(let number):
            "<integer>\(number)</integer>"
        case .float(let number):
            number.isFinite ? "<real>\(number)</real>" : nil
        case .boolean(let flag):
            flag ? "<true/>" : "<false/>"
        case .array(let items):
            all(items.map(element)).map { "<array>\($0.joined())</array>" }
        case .table(let table):
            all(
                table.keys.sorted().map { key in
                    table[key].flatMap(element).map { "<key>\(Escaping.xml(key))</key>\($0)" }
                }
            )
            .map { "<dict>\($0.joined())</dict>" }
        case .date:
            nil
        }
    }

    /// `elements`, or nil when one of them is nil.
    private static func all(_ elements: [String?]) -> [String]? {
        let written = elements.compactMap(\.self)
        return written.count == elements.count ? written : nil
    }
}
