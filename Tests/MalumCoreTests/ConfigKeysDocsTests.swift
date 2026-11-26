import Foundation
import Synchronization
import Testing

@testable import MalumCore

/// Checks that every key Malum's TOML files take has docs. Each file has an example that sets every
/// key its tables take. Reading it collects the keys each reader checks a table against, and each
/// of those keys has to show up in code in the file's part of `docs/`: in a TOML example or in
/// backticks. `malum.toml` and the curated tables of `macos.toml` are left out: their pages are
/// made from the schemas and the catalog, and CI fails when those pages are out of date.
///
/// A new key in a reader fails `everyExampleSetsEveryKey` until the example sets it, and then
/// `everyKeyHasDocs` until the docs name it.
@Suite(.timeLimit(.minutes(1)))
@MainActor
struct ConfigKeysDocsTests {
    /// A table a reader checked for keys it doesn't know.
    struct Checked: Sendable {
        /// The table's path in its file.
        let path: [String]
        /// The keys the table takes.
        let known: [String]
        /// The keys the example gives it.
        let given: [String]
    }

    /// Collects the tables the readers check.
    final class Log: Sendable {
        /// The tables so far.
        private let checked = Mutex<[Checked]>([])

        /// Adds a table.
        func add(_ table: Checked) {
            checked.withLock { $0.append(table) }
        }

        /// Every table so far.
        var all: [Checked] { checked.withLock { $0 } }
    }

    /// The tables `example`'s reader checks, with the keys a generated page covers left out, and
    /// the problems it finds.
    static func read(_ example: Example) -> (checked: [Checked], problems: [ConfigProblem]) {
        let log = Log()
        let record: @Sendable ([String], [String], ConfigTable) -> Void = { path, known, table in
            log.add(Checked(path: path, known: known, given: Array(table.keys)))
        }
        let problems = TableReader.$onKnownKeys.withValue(record) { example.read(example.text) }
        let checked = log.all.map { table in
            let known = table.known.filter { !example.generated(table.path + [$0]) }
            return Checked(path: table.path, known: known, given: table.given)
        }
        return (checked, problems)
    }

    @Test func everyExampleReadsWithoutProblems() {
        for example in Self.examples {
            let problems = Self.read(example).problems
            #expect(problems.isEmpty, "\(example.file): \(problems.map(\.message))")
        }
    }

    @Test func everyExampleSetsEveryKey() {
        for example in Self.examples {
            for table in Self.read(example).checked {
                let missing = table.known.filter { !table.given.contains($0) }
                let at = table.path.isEmpty ? "the top" : TableReader.dotted(table.path)
                #expect(missing.isEmpty, "the example of \(example.file) leaves out \(missing) at \(at)")
            }
        }
    }

    @Test func everyKeyHasDocs() throws {
        for example in Self.examples {
            var words: Set<Substring> = []
            for part in example.docs {
                let page = try DocsPage(part.page)
                let section = try #require(page.section(part.heading), "docs has no \(part)")
                words.formUnion(DocsPage.codeWords(in: section))
            }
            let keys = Set(Self.read(example).checked.flatMap(\.known))
            let missing = keys.filter { !words.contains(Substring($0)) }.sorted()
            #expect(missing.isEmpty, "\(example.file): no docs for \(missing) in \(example.docs)")
        }
    }

    @Test func everyAppHasAnExample() {
        #expect(Set(Self.apps.keys) == Set(AppConfigs.all.map(\.name)))
    }
}
