import Foundation

/// A page in `docs/`, read for its sections and the words in its code.
struct DocsPage {
    /// The folder of the pages, at the top of the repository.
    private static let folder = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("docs")

    /// The page's lines.
    let lines: [String]

    /// The page `name` in `docs/`, such as `keyboard.md`.
    init(_ name: String) throws {
        let text = try String(contentsOf: Self.folder.appendingPathComponent(name), encoding: .utf8)
        self.init(lines: text.components(separatedBy: "\n"))
    }

    /// A page of `lines`.
    init(lines: [String]) {
        self.lines = lines
    }

    /// The section under the heading `title`, matched without regard to case, with its subsections,
    /// the whole page when `title` is nil, or nil when there's no such heading.
    func section(_ title: String?) -> ArraySlice<String>? {
        guard let title else { return lines[...] }
        let headings = self.headings
        guard let start = headings.firstIndex(where: { $0.title.lowercased() == title.lowercased() }) else {
            return nil
        }
        let heading = headings[start]
        let end = headings[(start + 1)...].first { $0.level <= heading.level }?.line ?? lines.count
        return lines[heading.line..<end]
    }

    /// A heading outside code blocks.
    private struct Heading {
        /// Its line, from 0.
        let line: Int
        /// How many `#` it starts with.
        let level: Int
        /// Its text.
        let title: String
    }

    /// Each heading outside code blocks.
    private var headings: [Heading] {
        var inCode = false
        var headings: [Heading] = []
        for (number, line) in lines.enumerated() {
            if Self.isFence(line) { inCode.toggle() }
            let level = line.prefix { $0 == "#" }.count
            guard !inCode, level > 0, line.dropFirst(level).hasPrefix(" ") else { continue }
            headings.append(Heading(line: number, level: level, title: String(line.dropFirst(level + 1))))
        }
        return headings
    }

    /// The words in the code of `lines`: in code blocks and between backticks. A word is made of
    /// letters, digits, `_` and `-`, as TOML's bare keys are.
    static func codeWords(in lines: ArraySlice<String>) -> [Substring] {
        var inCode = false
        var code: [Substring] = []
        for line in lines {
            if isFence(line) {
                inCode.toggle()
                continue
            }
            let parts = line.split(separator: "`", omittingEmptySubsequences: false)
            code += inCode ? [line[...]] : parts.enumerated().filter { $0.offset % 2 == 1 }.map(\.element)
        }
        return code.flatMap { $0.split { !($0.isLetter || $0.isNumber || $0 == "_" || $0 == "-") } }
    }

    /// Whether `line` opens or closes a code block.
    private static func isFence(_ line: String) -> Bool {
        line.drop { $0 == " " }.hasPrefix("```")
    }
}
