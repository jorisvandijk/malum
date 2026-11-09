import Testing

@testable import MalumCore

@Suite(.timeLimit(.minutes(1)))
struct FuzzyMatchTests {
    @Test func emptyQueryMatchesWithZero() {
        #expect(FuzzyMatch.score("  ", in: "Safari") == 0)
    }

    @Test func lettersOutOfOrderDontMatch() {
        #expect(FuzzyMatch.score("fs", in: "Safari") == nil)
    }

    @Test func longerQueryThanNameDoesntMatch() {
        #expect(FuzzyMatch.score("safaris", in: "Safari") == nil)
    }

    @Test func caseAccentsAndSpacesDontCount() {
        #expect(FuzzyMatch.score("CAFE app", in: "Café App") != nil)
    }

    @Test func startOfNameBeatsMiddle() {
        let start = FuzzyMatch.score("mail", in: "Mail") ?? 0
        let middle = FuzzyMatch.score("mail", in: "Thunderbird Mail Helper") ?? 0
        #expect(start > middle)
    }

    @Test func wordStartsBeatScatteredLetters() {
        let words = FuzzyMatch.score("ss", in: "System Settings") ?? 0
        let scattered = FuzzyMatch.score("ss", in: "Glasses") ?? 0
        #expect(words > scattered)
    }

    @Test func capitalAfterSmallLetterStartsAWord() {
        let camel = FuzzyMatch.score("s", in: "xSettings") ?? 0
        let plain = FuzzyMatch.score("s", in: "xsettings") ?? 0
        #expect(camel > plain)
    }

    @Test func lettersInARowBeatAGap() {
        let run = FuzzyMatch.score("cod", in: "xcodium") ?? 0
        let gap = FuzzyMatch.score("cod", in: "xcaoadium") ?? 0
        #expect(run > gap)
    }

    @Test func rankDropsMisses() {
        let ranked = FuzzyMatch.rank(["Safari", "Mail", "Maps"], query: "ma", name: { $0 }, ties: { $0 < $1 })
        #expect(ranked == ["Mail", "Maps"])
    }

    @Test func rankPutsTheBestFirst() {
        let ranked = FuzzyMatch.rank(["Thunderbird", "Terminal"], query: "te", name: { $0 }, ties: { $0 < $1 })
        #expect(ranked == ["Terminal", "Thunderbird"])
    }

    @Test func tiesDecideEqualScores() {
        let ranked = FuzzyMatch.rank(["Mail", "Maps"], query: "ma", name: { $0 }, ties: { $0 > $1 })
        #expect(ranked == ["Maps", "Mail"])
    }
}
