import Testing

@Suite(.timeLimit(.minutes(1)))
struct DocsPageTests {
    @Test func codeWordsComeFromExamplesAndBackticks() {
        let lines = ["Set `hyper_key` here.", "```toml", "[remap]", "fn = \"left_control\"", "```", "plain words"]
        #expect(DocsPage.codeWords(in: lines[...]) == ["hyper_key", "remap", "fn", "left_control"])
    }

    @Test func aSectionEndsAtTheNextHeadingAtItsLevel() {
        let page = DocsPage(lines: ["# Page", "## One", "a", "### Sub", "b", "```", "# not a heading", "```", "## Two"])
        #expect(page.section("one") == ["## One", "a", "### Sub", "b", "```", "# not a heading", "```"])
        #expect(page.section("Sub") == ["### Sub", "b", "```", "# not a heading", "```"])
        #expect(page.section("not a heading") == nil)
        #expect(page.section(nil)?.count == 9)
    }
}
