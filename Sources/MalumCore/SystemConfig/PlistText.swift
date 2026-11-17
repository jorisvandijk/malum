import Foundation

/// Property lists, the format `defaults` takes an app's preferences in, one value at a time.
enum PlistText {
    /// The two lines every property list document starts with.
    static let header = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        """

    /// `value` as a property list document, or nil when it isn't text, a number, true or false,
    /// or a list or table of them.
    static func document(_ value: ConfigValue) -> String? {
        element(value).map { element in
            """
            \(header)
            <plist version="1.0">\(element)</plist>
            """
        }
    }

    /// `value` written as JSON, as a property list document of its bytes, for apps that keep each
    /// preference as JSON, or nil when it can't be JSON.
    static func jsonData(_ value: ConfigValue) -> String? {
        JSONText.value(value).map { json in
            """
            \(header)
            <plist version="1.0"><data>\(Data(json.utf8).base64EncodedString())</data></plist>
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
            items.map(element).allPresent().map { "<array>\($0.joined())</array>" }
        case .table(let table):
            table.keys.sorted().map { key in
                table[key].flatMap(element).map { "<key>\(Escaping.xml(key))</key>\($0)" }
            }
            .allPresent().map { "<dict>\($0.joined())</dict>" }
        case .date:
            nil
        }
    }
}
