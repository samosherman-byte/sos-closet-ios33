import Foundation
import Testing
@testable import SOSCloset

// The catalog mapping (APP-SPEC §3.1, Tests): the cases of the site's app/lib/catalog/catalog.test.ts, and every piece
// of the sample store mapped exactly as data/catalog.json has it.

@Suite("The sample store, read the way Shopify delivers it",
    .enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh (SampleStore/ is git-ignored)"))
struct SampleStoreTests {
    let pieces = SampleFiles.pieces
    let items = SampleFiles.catalogJSON.items

    @Test func carriesThePhotoSizeStandardMeasuredOnItsCovers() {
        let fitted = pieces.compactMap(\.fit)
        #expect(fitted.count > 100)
        for fit in fitted {
            #expect(fit.scale > 0.2)
            #expect(fit.scale <= 1.4)
            #expect(fit.drop >= 0)
        }
    }

    @Test func hasEveryPieceOfThePrototypeInItsOrder() {
        // Newest first, the hold-back applied.
        let expected = holdBack(items.map { Piece.stub($0.id) }, [("c179", "c45")]).map(\.id)
        #expect(items.count == 198)
        #expect(pieces.map(\.id) == expected)
        #expect(pieces.count == items.count)
    }

    /// What catalog.json says of a piece, in the piece's terms.
    nonisolated struct Mapped: Equatable, CustomStringConvertible {
        var id: String
        var dept: Dept?
        var cat: String?
        var sub: String?
        var designer: String
        var title: String
        var detail: String
        var price: Double
        var sizes: [String]
        var colors: [String]
        var tags: [String]
        var noDesigner: Bool

        var description: String {
            "\(id): \(dept?.rawValue ?? "-") / \(cat ?? "-") / \(sub ?? "-") · \(designer) · \(title) · \(detail) · "
                + "\(price) · \(sizes) · \(colors) · \(tags) · noDesigner \(noDesigner)"
        }
    }

    @Test func mapsEveryPieceExactlyAsThePrototypeHasIt() throws {
        let byID = Dictionary(pieces.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a })
        // (Jewelry & Objects since November 1: the prototype, like the store, still lists Art & Home's pieces as dept
        // home. The piece leading the case carries the featured tag: data/merch.json, case.)
        let featured = Set(try #require(SampleFiles.merch).caseStandIns.featured)
        for x in items {
            let p = try #require(byID[x.id], "\(x.id) is missing")
            let got = Mapped(
                id: p.id, dept: p.dept, cat: p.cat, sub: p.sub, designer: p.designer, title: p.title, detail: p.detail,
                price: p.price, sizes: p.sizes, colors: p.colors, tags: p.tags, noDesigner: p.noDesigner)
            let want = Mapped(
                id: x.id, dept: x.s == "home" ? .jewelry : Dept(rawValue: x.s), cat: x.c, sub: x.sub, designer: x.b,
                title: x.t, detail: x.d, price: x.p, sizes: x.sz ?? [], colors: x.col,
                tags: (x.tg ?? []) + (featured.contains(x.id) ? ["featured"] : []), noDesigner: x.nd ?? false)
            #expect(got == want)
            // The cover is the sample store's own photo file, in the app's (here the repo's) SampleStore folder.
            let url = try #require(p.image?.url)
            #expect(url.isFileURL)
            #expect(url.lastPathComponent.wholeMatch(of: /[0-9a-f]+\.jpg/) != nil, "\(url)")
            #expect(url.deletingLastPathComponent().path(percentEncoded: false).hasSuffix("SampleStore/prototype/img/"))
            #expect(FileManager.default.fileExists(atPath: url.path(percentEncoded: false)), "\(url)")
        }
    }

    @Test func hasNoStructureProblems() {
        #expect(SampleFiles.records.filter { !structureProblems($0).isEmpty }.map(\.handle) == [])
    }

    @Test func readsTheGucciJackiesExtrasAndTheSuitsSizes() throws {
        let jackie = SampleFiles.record("gucci-jackie-1961-medium-tote")
        #expect(jackie.images.count == 5)
        #expect(jackie.metafields.authenticated)
        #expect(jackie.metafields.colorName == "Emerald green")
        #expect(jackie.metafields.swatch == "#1F5A3E")
        #expect(jackie.metafields.details.count == 8)
        // Its card swipes through its four photos of the bag (SPEC §7); the heat stamp waits for its page, under
        // Labels & markings (SPEC §10, Which photos go where).
        #expect(toPiece(jackie)?.morePhotos?.count == 3)
        let page = try #require(toProductDetail(jackie))
        #expect(page.photos.count == 4)
        #expect(page.proof.count == 1)
        #expect(page.proof.first?.alt.contains("heat stamp") == true)
        // No tag and no hangtag photo: pre-owned.
        #expect(!page.newWithTags)
        let suit = SampleFiles.record("coppley-custom-windowpane-suit-light-beige")
        #expect(suit.variants.map(\.size) == ["40R", "42R", "44R", "46R", "48R"])
    }

    @Test func givesTheCaseItsStoryLines() {
        // (Jewelry & Objects is a case in the sample store: fewer than 12 pieces, each with its line.)
        #expect(isCaseDept(pieces, .jewelry))
        #expect(!isCaseDept(pieces, .women))
        let jewelry = deptPieces(pieces, .jewelry)
        #expect(!jewelry.isEmpty)
        #expect(jewelry.contains { $0.story != nil })
        #expect(pieces.filter { $0.dept != .jewelry }.allSatisfy { $0.story == nil })
        let arabia = pieces.first { $0.id == "arabia" }
        #expect(arabia?.story != nil)
        #expect(arabia?.story == SampleFiles.merch?.caseStandIns.story["arabia"])
        #expect(arabia?.tags.contains("featured") == true)
    }
}

@Suite("New with tags (SPEC §10): the tag, or a hangtag photo; every other piece pre-owned",
    .enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
struct NewWithTagsTests {
    func page(_ handle: String) -> ProductDetail? { toProductDetail(SampleFiles.record(handle)) }

    @Test func theSampleStoresTaggedPiecesSayItWithNoHangtagPhoto() {
        for handle in [
            "hill-house-home-the-zinnia-nap-top",
            "coppley-custom-windowpane-suit-light-beige",
            "avenue-21-floral-jacquard-dinner-jacket",
            "hill-house-home-floral-high-waist-shorts",
            "edward-achour-wide-leg-button-detail-pants",
        ] {
            #expect(SampleFiles.record(handle).tags.contains("New with tags"), "\(handle)")
            #expect(page(handle)?.newWithTags == true, "\(handle)")
        }
        #expect(page("gucci-jackie-1961-medium-tote")?.newWithTags == false)
        #expect(page("staud-gus-leather-pants-earth-brown")?.newWithTags == false)
    }

    @Test func aHangtagPhotoStillSaysItWithoutTheTag() throws {
        var r = SampleFiles.record("staud-gus-leather-pants-earth-brown")
        var tag = r.images[0]
        tag.alt = "STAUD Gus leather pants – hangtag"
        r.images.append(tag)
        let p = try #require(toProductDetail(r))
        #expect(!r.tags.contains("New with tags"))
        #expect(p.newWithTags)
        // (The hangtag photo itself isn't shown.)
        #expect(p.photos.count == 1)
        #expect(p.proof.isEmpty)
    }

    @Test func theTagSetsTheConditionAndNothingElse() {
        let t = parseTags(["dept:men", "New with tags", "Vintage"])
        #expect(t.newWithTags)
        #expect(t.plain == ["Vintage"])
        #expect(parseTags(["New With Tags"]).newWithTags)
        #expect(parseTags([" new with tags "]).newWithTags)
        for other in ["NWT", "New with tag", "New", "new-with-tags"] {
            #expect(!parseTags([other]).newWithTags, "\(other)")
        }
        #expect(toPiece(SampleFiles.record("coppley-custom-windowpane-suit-light-beige"))?.tags.contains("New with tags") == false)
        #expect(!SampleFiles.pieces.contains { $0.tags.contains("New with tags") })
    }

    @Test func eitherOneIsEnough() {
        #expect(isNewWithTags(["New with tags"], hangtag: false))
        #expect(isNewWithTags([], hangtag: true))
        #expect(!isNewWithTags(["dept:women", "Vintage"], hangtag: false))
    }
}

@Suite("A pre-owned piece's grade (SPEC §10): condition:like-new or condition:excellent")
struct GradeTests {
    @Test func parseTagsReadsItAsAStructuredTag() {
        let t = parseTags(["dept:women", "condition:like-new", "Vintage"])
        #expect(t.grade == .likeNew)
        #expect(t.plain == ["Vintage"])
        #expect(parseTags(["condition:excellent"]).grade == .excellent)
        #expect(parseTags(["Condition:Like-New"]).grade == .likeNew)
        #expect(parseTags([" condition: like new "]).grade == .likeNew)
        #expect(parseTags(["condition:EXCELLENT"]).grade == .excellent)
        #expect(parseTags(["dept:women", "Vintage"]).grade == nil)
    }

    @Test func onlyTheTwoTopGrades() {
        for other in [
            "condition:good", "condition:fair", "condition:very-good", "condition:new", "condition:", "like-new",
            "Like new", "Excellent",
        ] {
            let t = parseTags([other])
            #expect(t.grade == nil, "\(other)")
            if other.hasPrefix("condition") { #expect(!t.plain.contains(other), "\(other)") }
        }
    }

    @Test func twoGradesOnOnePieceTakeTheLowerOne() {
        #expect(parseTags(["condition:like-new", "condition:excellent"]).grade == .excellent)
        #expect(parseTags(["condition:excellent", "condition:like-new"]).grade == .excellent)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func neverAPlainTag() throws {
        let maje = SampleFiles.record("maje-loiso-satin-tie-neck-blouse")
        #expect(maje.tags.contains("condition:like-new"))
        let p = try #require(toPiece(maje))
        #expect(p.tags == [])
        // (Nowhere in the piece, its photos' descriptions included.)
        #expect(String(describing: p).lowercased().firstMatch(of: /like.new|excellent|condition/) == nil)
        for q in SampleFiles.pieces {
            #expect(String(describing: q).lowercased().firstMatch(of: /condition:|like.new/) == nil, "\(q.id)")
        }
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func carriedOntoTheProductPage() {
        #expect(toProductDetail(SampleFiles.record("maje-loiso-satin-tie-neck-blouse"))?.grade == .likeNew)
        #expect(toProductDetail(SampleFiles.record("nolan-miller-beaded-satin-lapel-tuxedo-blazer"))?.grade == .excellent)
        #expect(toProductDetail(SampleFiles.record("coach-legacy-pebbled-leather-hobo-graphite"))?.grade == nil)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func newWithTagsNeverHasOne() throws {
        var stray = SampleFiles.record("coppley-custom-windowpane-suit-light-beige")
        stray.tags.append("condition:like-new")
        let t = parseTags(stray.tags)
        #expect(t.newWithTags)
        #expect(t.grade == .likeNew)
        let p = try #require(toProductDetail(stray))
        #expect(p.newWithTags)
        #expect(p.grade == nil)
        // A hangtag photo makes it New with tags too, and so takes the grade away.
        var maje = SampleFiles.record("maje-loiso-satin-tie-neck-blouse")
        var tag = maje.images[0]
        tag.alt = "Maje Loiso blouse – hangtag"
        maje.images.append(tag)
        let mp = try #require(toProductDetail(maje))
        #expect(mp.newWithTags)
        #expect(mp.grade == nil)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func theSampleStoreHasThePrototypesGrades() {
        let grades = SampleFiles.records.map { parseTags($0.tags).grade }
        #expect(grades.filter { $0 == .likeNew }.count == 87)
        #expect(grades.filter { $0 == .excellent }.count == 32)
        #expect(SampleFiles.records.filter { let t = parseTags($0.tags); return t.grade != nil && t.newWithTags }.isEmpty)
    }
}

@Suite("Mapping a product")
struct MappingTests {
    func rec(
        productType: String = "Clothing", images: [PieceImage] = [], coverId: String? = nil,
        variants: [Variant] = [Variant(id: "1", size: "M", available: true, price: 100)], photoFit: String? = nil
    ) -> ProductRecord {
        ProductRecord(
            handle: "x", title: "X", vendor: "V", productType: productType, tags: [], createdAt: "2026-10-10T00:00:00Z",
            images: images, coverId: coverId, variants: variants, metafields: .init(photoFit: photoFit))
    }

    @Test func readsTheStructureTags() {
        let t = parseTags([
            "dept:women", "cat:clothing", "sub:tops-blouses", "color:red", "color:nope", "id:c1", "Vintage", "no-designer",
        ])
        #expect(
            t
                == ParsedTags(
                    dept: .women, cat: "Clothing", sub: "Tops & Blouses", colors: ["red"], id: "c1", noDesigner: true,
                    newWithTags: false, grade: nil, plain: ["Vintage"]))
        #expect(parseTags(["sub:womens-watches"]).sub == "Women’s Watches")
        // dept:home is Jewelry & Objects (November 1).
        #expect(parseTags(["dept:home"]).dept == .jewelry)
    }

    @Test func splitsAOnePieceSMIntoSAndM() {
        #expect(splitSize("S/M") == ["S", "M"])
    }

    @Test func takesThePhotoSizeStandardOnlyWhenMeasuredOnTheCover() {
        func json(_ v: [String: Any]) -> String {
            String(data: try! JSONSerialization.data(withJSONObject: v), encoding: .utf8)!
        }
        func fit(_ value: Any, coverId: String = "gid://shopify/MediaImage/7") -> PhotoFit? {
            photoFit(rec(coverId: coverId, photoFit: (value as? String) ?? json(value as! [String: Any])))
        }
        let stored: [String: Any] = ["scale": 0.83, "drop": 11, "imageId": "gid://shopify/MediaImage/7"]
        func with(_ more: [String: Any]) -> [String: Any] { stored.merging(more) { _, new in new } }
        #expect(fit(stored) == PhotoFit(scale: 0.83, drop: 11))
        #expect(toPiece(rec(coverId: "gid://shopify/MediaImage/7", photoFit: json(stored)))?.fit == PhotoFit(scale: 0.83, drop: 11))
        // A new cover: left as it is until it's measured.
        #expect(fit(stored, coverId: "gid://shopify/MediaImage/8") == nil)
        #expect(fit(stored, coverId: "") == nil)
        // Nothing to change (a photo left as it is), or a value the tool wouldn't write.
        #expect(fit(with(["scale": 1, "drop": 0])) == nil)
        #expect(fit(with(["scale": 2])) == nil)
        #expect(fit(with(["drop": -3])) == nil)
        #expect(fit(with(["scale": "big"])) == nil)
        #expect(fit("{not json") == nil)
        #expect(toPiece(rec())?.fit == nil)
        // Where the piece's top sits: kept when it's there and sensible.
        #expect(fit(with(["top": 38.5])) == PhotoFit(scale: 0.83, drop: 11, top: 38.5))
        #expect(fit(with(["top": 140])) == PhotoFit(scale: 0.83, drop: 11))
        #expect(fit(with(["top": "high"])) == PhotoFit(scale: 0.83, drop: 11))
        #expect(fit(with(["scale": 1, "drop": 0, "top": 4.2])) == PhotoFit(scale: 1, drop: 0, top: 4.2))
    }

    @Test func carriesThePhotosAfterTheCoverForTheCard() throws {
        func photo(_ n: Int) -> PieceImage {
            PieceImage(url: URL(string: "https://cdn.shopify.com/\(n).jpg")!, alt: "Photo \(n)", width: 2000, height: 2500)
        }
        let one = try #require(toPiece(rec(images: [photo(1)])))
        #expect(one.image?.url.absoluteString == "https://cdn.shopify.com/1.jpg")
        #expect(one.morePhotos == nil)
        let three = try #require(toPiece(rec(images: [1, 2, 3].map(photo))))
        #expect(three.image == photo(1))
        #expect(
            three.morePhotos == [
                CardPhoto(url: URL(string: "https://cdn.shopify.com/2.jpg")!, width: 2000),
                CardPhoto(url: URL(string: "https://cdn.shopify.com/3.jpg")!, width: 2000),
            ])
        // Twenty at most, as on its page.
        #expect(toPiece(rec(images: (1...25).map(photo)))?.morePhotos?.count == 19)
    }

    @Test func keepsOnlySizesStillInStockAndDropsAPieceWithNothingLeft() {
        let p = toPiece(
            rec(variants: [
                Variant(id: "1", size: "40R", available: false, price: 1200),
                Variant(id: "2", size: "42R", available: true, price: 1200),
            ]))
        #expect(p?.sizes == ["42R"])
        #expect(toPiece(rec(variants: [Variant(id: "1", size: "M", available: false, price: 1)])) == nil)
        // (A sold piece stays for its own page: no sizes, the price it was.)
        let sold = toPiece(rec(variants: [Variant(id: "1", size: "M", available: false, price: 80)]), sold: true)
        #expect(sold?.sizes == [])
        #expect(sold?.price == 80)
    }

    @Test func thePriceIsTheLowestOfTheSizesStillForSale() {
        let p = toPiece(
            rec(variants: [
                Variant(id: "1", size: "S", available: false, price: 50),
                Variant(id: "2", size: "M", available: true, price: 120),
                Variant(id: "3", size: "L", available: true, price: 90),
            ]))
        #expect(p?.price == 90)
        #expect(p?.sizes == ["M", "L"])
    }

    @Test func fallsBackOnTheProductTypeAndAnUnambiguousCategory() {
        let bag = toPiece(rec(productType: "Handbags"))
        #expect(bag?.dept == .women)
        #expect(bag?.cat == "Handbags")
        #expect(bag?.sub == nil)
        #expect(bag?.id == "x")
        let clothing = toPiece(rec(productType: "Clothing"))
        #expect(clothing?.dept == nil)
        #expect(clothing?.cat == "Clothing")
    }

    @Test func storyLineFromTheMetafieldOrTheFirstShortSentence() {
        var r = rec()
        r.descriptionHtml = "<p>A hand-painted cel&nbsp;of Archie &amp; friends. Signed.</p>"
        #expect(storyOf(r) == "A hand-painted cel of Archie & friends.")
        r.metafields.story = "  Its own   line. "
        #expect(storyOf(r) == "Its own line.")
        r.metafields.story = nil
        r.descriptionHtml = String(repeating: "word ", count: 40) + "end."
        #expect(storyOf(r) == "")
        r.summary = "Short summary first. Then more"
        #expect(storyOf(r) == "Short summary first.")
    }

    @Test func holdBackMovesAPieceJustAfterTheOneNamed() {
        let list = ["a", "b", "c", "d"].map { Piece.stub($0) }
        #expect(holdBack(list, [("a", "c")]).map(\.id) == ["b", "c", "a", "d"])
        // (Named piece missing: it stays where it was.)
        #expect(holdBack(list, [("b", "z")]).map(\.id) == ["a", "b", "c", "d"])
    }

    @Test func newestFirstThenTheImportInItsOrderThenTheStoresOwnHoldBacks() {
        let input = [
            OrderInput(piece: .stub("c45"), createdAt: "2026-10-01T00:00:00Z"),
            OrderInput(piece: .stub("new-1"), createdAt: "2026-10-20T00:00:00Z"),
            OrderInput(piece: .stub("coach-legacy"), createdAt: "2026-10-01T00:00:00Z"),
            OrderInput(piece: .stub("new-2"), createdAt: "2026-10-25T00:00:00Z"),
            OrderInput(piece: .stub("c179"), createdAt: "2026-10-01T00:00:00Z"),
        ]
        // HOLD_BACK (c179 after c45) applies while no piece has custom.place_after.
        #expect(orderPieces(input).map(\.id) == ["new-2", "new-1", "coach-legacy", "c45", "c179"])
        // Once one does, the store's setting wins and the list is ignored.
        var placed = input
        placed[1].placeAfter = "coach-legacy"
        #expect(orderPieces(placed).map(\.id) == ["new-2", "coach-legacy", "new-1", "c179", "c45"])
    }
}
