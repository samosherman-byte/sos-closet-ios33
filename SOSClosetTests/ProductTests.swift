import Foundation
import Testing
@testable import SOSCloset

// The product page (APP-SPEC §3.5; SPEC §10): the status beside the price, the same cases as the site's
// app/lib/catalog/status.test.ts; "You may also like" and Details, as ProductPage.tsx has them; and the description as
// the page reads Shopify's HTML.

private func facts(
    authenticated: Bool = false, tags: [String] = [], detail: String = "Navy", newWithTags: Bool = false,
    grade: Grade? = nil, sizes: [String] = [], fnote: String? = nil
) -> StatusFacts {
    StatusFacts(
        authenticated: authenticated, tags: tags, detail: detail, newWithTags: newWithTags, grade: grade, sizes: sizes,
        fnote: fnote)
}

/// A sample-store page's line, in words.
private func line(_ handle: String) -> String {
    statusLine(StatusFacts(toProductDetail(SampleFiles.record(handle))!))
}

@Suite("The status line: every piece states its condition")
struct StatusLineTests {
    @Test func aPlainPieceSaysPreOwnedAndNothingElse() {
        #expect(statusMarks(facts()) == [StatusMark(text: "Pre-owned")])
        #expect(statusLine(facts()) == "Pre-owned")
        #expect(conditionOf(newWithTags: false) == "Pre-owned")
    }

    @Test func newWithTagsInPlaceOfPreOwnedNeverBoth() {
        #expect(statusMarks(facts(newWithTags: true, sizes: ["S"])) == [
            StatusMark(text: "Size S"), StatusMark(text: "New with tags"),
        ])
        #expect(conditionOf(newWithTags: true) == "New with tags")
    }

    @Test func theSizeFirstThenAuthenticatedVintageAndTheCondition() {
        #expect(statusLine(facts(authenticated: true, sizes: ["40R"])) == "Size 40R · Authenticated · Pre-owned")
        // (A label in another system keeps its US size after it.)
        #expect(
            statusLine(facts(tags: ["Vintage"], detail: "Vintage 1980s · Red", sizes: ["IT 42"], fnote: "US 6"))
                == "Size IT 42 (US 6) · Vintage 1980s · Pre-owned")
        #expect(statusLine(facts(newWithTags: true, sizes: ["8", "10"])) == "Sizes 8, 10 · New with tags")
        #expect(
            statusLine(facts(authenticated: true, tags: ["Vintage"], detail: "Vintage · Black", sizes: ["M"]))
                == "Size M · Authenticated · Vintage · Pre-owned")
    }

    @Test func noSizeTheRestKeepTheirOrder() {
        #expect(statusLine(facts(authenticated: true)) == "Authenticated · Pre-owned")
        #expect(statusLine(facts(tags: ["Vintage"], detail: "Vintage · Red")) == "Vintage · Pre-owned")
        #expect(statusLine(facts(newWithTags: true)) == "New with tags")
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func onTheSampleStoresPages() {
        #expect(line("gucci-jackie-1961-medium-tote") == "Authenticated · Pre-owned Like new")
        #expect(line("coach-legacy-pebbled-leather-hobo-graphite") == "Pre-owned")
        #expect(line("gucci-double-breasted-wool-blazer-red") == "Size IT 42 (US 6) · Vintage 1980s · Pre-owned")
        #expect(line("coppley-custom-windowpane-suit-light-beige") == "Sizes 40R, 42R, 44R, 46R, 48R · New with tags")
    }
}

@Suite("A pre-owned piece's grade follows Pre-owned")
struct StatusGradeTests {
    @Test func theGradeRidesOnTheConditionMarkNotAsAMarkOfItsOwn() {
        #expect(statusMarks(facts(grade: .likeNew, sizes: ["S"])) == [
            StatusMark(text: "Size S"), StatusMark(text: "Pre-owned", grade: .likeNew),
        ])
        // (A real space before it, so the line reads, and a screen reader says, two words.)
        #expect(statusLine(facts(grade: .likeNew, sizes: ["S"])) == "Size S · Pre-owned Like new")
        #expect(
            statusLine(facts(tags: ["Vintage"], detail: "Vintage · Black · Size 10", grade: .excellent, sizes: ["10"]))
                == "Size 10 · Vintage · Pre-owned Excellent")
    }

    @Test func gradedWithNoSizeTheGradeStillClosesTheLine() {
        #expect(statusMarks(facts(authenticated: true, grade: .likeNew)) == [
            StatusMark(text: "Authenticated"), StatusMark(text: "Pre-owned", grade: .likeNew),
        ])
        #expect(statusLine(facts(authenticated: true, grade: .likeNew)) == "Authenticated · Pre-owned Like new")
        #expect(statusLine(facts(grade: .excellent)) == "Pre-owned Excellent")
    }

    @Test func ungradedPreOwnedAloneNeverALowerGrade() {
        #expect(statusMarks(facts(sizes: ["M"])) == [StatusMark(text: "Size M"), StatusMark(text: "Pre-owned")])
        #expect(!statusMarks(facts()).contains { $0.grade != nil })
    }

    @Test func newWithTagsNeverShowsAGradeEvenWithOneSet() {
        #expect(statusMarks(facts(newWithTags: true, grade: .likeNew, sizes: ["XS"])) == [
            StatusMark(text: "Size XS"), StatusMark(text: "New with tags"),
        ])
        #expect(statusLine(facts(newWithTags: true, grade: .excellent)) == "New with tags")
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func newWithTagsPlusAStrayConditionTagFromTheProductToTheLine() {
        var suit = SampleFiles.record("coppley-custom-windowpane-suit-light-beige")
        suit.tags.append("condition:like-new")
        let p = toProductDetail(suit)!
        #expect(p.grade == nil)
        #expect(!statusMarks(StatusFacts(p)).contains { $0.grade != nil })
        #expect(statusLine(StatusFacts(p)) == "Sizes 40R, 42R, 44R, 46R, 48R · New with tags")
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func onTheSampleStoresPages() {
        #expect(line("maje-loiso-satin-tie-neck-blouse") == "Size S · Pre-owned Like new")
        #expect(line("nolan-miller-beaded-satin-lapel-tuxedo-blazer") == "Size 10 · Vintage · Pre-owned Excellent")
        #expect(
            line("comptoir-des-cotonniers-mamika-tweed-double-breasted-jacket")
                == "Size FR 38 (US 6) · Pre-owned Excellent")
        // (New with tags as eBay lists them, Sam's call where the closets disagreed: no grade.)
        #expect(line("hill-house-home-floral-high-waist-shorts") == "Size XS · New with tags")
        #expect(line("edward-achour-wide-leg-button-detail-pants") == "Size 4 · New with tags")
    }
}

@Suite("You may also like, and Details")
struct AlsoLikeTests {
    private func piece(_ id: String, _ dept: Dept, _ cat: String) -> Piece {
        var p = Piece.stub(id)
        p.dept = dept
        p.cat = cat
        return p
    }

    @Test func sixFromTheSameCategoryToppedUpFromTheDepartment() {
        let me = piece("me", .women, "Handbags")
        let list = [
            piece("s1", .women, "Shoes"), me, piece("h1", .women, "Handbags"), piece("m1", .men, "Handbags"),
            piece("h2", .women, "Handbags"), piece("c1", .women, "Clothing"), piece("c2", .women, "Clothing"),
            piece("c3", .women, "Clothing"), piece("c4", .women, "Clothing"),
        ]
        // The category first (in the closet's order), then the rest of the department, never the piece itself or
        // another department.
        #expect(alsoLike(me, list).map(\.id) == ["h1", "h2", "s1", "c1", "c2", "c3"])
        let handbags = (1...8).map { piece("h\($0)", .women, "Handbags") }
        #expect(alsoLike(me, [me] + handbags).map(\.id) == ["h1", "h2", "h3", "h4", "h5", "h6"])
        #expect(alsoLike(me, [me]).isEmpty)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func theJackiesPage() {
        let jackie = SampleFiles.pieces.first { $0.id == "jackie" }!
        let also = alsoLike(jackie, SampleFiles.pieces)
        #expect(also.count == 6)
        #expect(also.allSatisfy { $0.dept == .women && $0.cat == "Handbags" && $0.id != "jackie" })
        // Its written facts already say it's authenticated: no second line about the card.
        let detail = toProductDetail(SampleFiles.record("gucci-jackie-1961-medium-tote"))!
        #expect(detailsList(detail) == detail.details)
        #expect(detailsList(detail).first == "Authentic Gucci, professionally authenticated")
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func anAuthenticatedPieceWithoutWrittenFactsShowsItsCard() {
        var r = SampleFiles.record("gucci-jackie-1961-medium-tote")
        r.metafields.details = ["Emerald green calfskin leather"]
        #expect(detailsList(toProductDetail(r)!) == [
            "Emerald green calfskin leather", "Professionally authenticated, with authentication card",
        ])
        r.metafields.authenticated = false
        r.metafields.details = []
        #expect(detailsList(toProductDetail(r)!).isEmpty)
    }
}

@Suite("The description as the page reads it")
struct DescriptionTests {
    @Test func paragraphsAndTheirLineBreaks() {
        let blocks = descriptionBlocks("<p>A Gucci tote.<br>In green.</p>\n<p>  Gold-tone   hardware. </p><p></p>")
        #expect(blocks == [.paragraph("A Gucci tote.\nIn green."), .paragraph("Gold-tone hardware.")])
        // Closed, they run on as one flow, a space apart.
        #expect(descriptionFlow(blocks) == "A Gucci tote. In green. Gold-tone hardware.")
    }

    @Test func listsAndPlainText() {
        let blocks = descriptionBlocks("Intro line<ul><li>One</li><li><strong>Two</strong> parts</li></ul><div>End</div>")
        #expect(blocks == [.paragraph("Intro line"), .item("One"), .item("Two parts"), .paragraph("End")])
        #expect(descriptionBlocks("").isEmpty)
        #expect(descriptionBlocks("Just words.") == [.paragraph("Just words.")])
    }

    @Test func entitiesAreRead() {
        #expect(decodeEntities("men&#x27;s &quot;Desert Sage&quot; &amp; more") == "men's \"Desert Sage\" & more")
        #expect(decodeEntities("Gucci&rsquo;s&nbsp;Jackie &#8212; caf&eacute;") == "Gucci’s Jackie — café")
        // (An ampersand that isn't an entity stays.)
        #expect(decodeEntities("Dolce & Gabbana &unknown; A&B") == "Dolce & Gabbana &unknown; A&B")
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func everySampleDescriptionReadsAsText() {
        for r in SampleFiles.records where !r.descriptionHtml.isEmpty {
            let flow = descriptionFlow(descriptionBlocks(r.descriptionHtml))
            #expect(!flow.isEmpty, "\(r.handle)")
            #expect(!flow.contains("<") && !flow.contains("&quot;") && !flow.contains("&#"), "\(r.handle)")
        }
    }
}
