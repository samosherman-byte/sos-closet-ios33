import Foundation
import Testing
@testable import SOSCloset

// Shop All and the departments (APP-SPEC §3.2, §3.3): the sections against what the site's prototype showed on each
// page as it opens (the site's test/golden files, its golden.test.ts), the case's order, and the photo size standard
// on cards (the site's 06-browse.css: --cut, --fd, --fs, --fk).

/// The site's golden files: for each scenario, what its prototype showed before any tap (the first snapshot).
private nonisolated enum Golden {
    struct Scenario: Decodable { var name: String; var page: String; var query: String; var width: String }
    struct Recorded: Decodable { var name: String; var snaps: [Snap] }
    struct Snap: Decodable {
        var layout: String
        var sections: [Section]
        var cards: [String]
        var cutouts: [Cutout]?
    }
    struct Section: Decodable { var name: String; var cards: [String]; var subs: [Sub] }
    struct Sub: Decodable { var type: String; var cards: [String] }
    struct Cutout: Decodable { var v: String }

    static let folder = SampleFiles.folder.appending(path: "test/golden")
    static var available: Bool {
        SampleFiles.available
            && FileManager.default.fileExists(atPath: folder.appending(path: "prototype.json").path(percentEncoded: false))
    }

    /// Each browse page's first snapshot with no typed search, by page.
    static let firstSnaps: [(scenario: String, page: String, snap: Snap)] = {
        guard let s = try? Data(contentsOf: folder.appending(path: "scenarios.json")),
            let r = try? Data(contentsOf: folder.appending(path: "prototype.json")),
            let scenarios = try? JSONDecoder().decode([Scenario].self, from: s),
            let recorded = try? JSONDecoder().decode([Recorded].self, from: r)
        else { return [] }
        let byName = Dictionary(recorded.map { ($0.name, $0) }, uniquingKeysWith: { a, _ in a })
        return scenarios.compactMap { sc in
            guard ["shop", "women", "men", "jewelry"].contains(sc.page), sc.query.isEmpty,
                let snap = byName[sc.name]?.snaps.first
            else { return nil }
            return (sc.name, sc.page, snap)
        }
    }()
}

private let places: [String: ShopPlace] = ["shop": .all, "women": .women, "men": .men, "jewelry": .jewelry]

@Suite("Shop All and the departments")
struct BrowseTests {
    @Test(.enabled(if: Golden.available, "The golden files aren't here: run tools/sync-sample-store.sh"))
    func everyPageAsTheSitesPrototypeShowsIt() throws {
        #expect(Golden.firstSnaps.count >= 3)
        for (name, page, snap) in Golden.firstSnaps {
            let model = Browse.page(places[page]!, pieces: SampleFiles.pieces)
            if model.isCase {
                // (The recorder reads a case, one run of pieces with no headings, as a grid.)
                #expect(snap.layout == "grid", "\(name)")
                #expect(model.casePieces.map(\.id) == snap.cards, "\(name)")
                continue
            }
            #expect(snap.layout == "sections", "\(name)")
            #expect(model.sections.map(\.name) == snap.sections.map(\.name), "\(name)")
            for (ours, theirs) in zip(model.sections, snap.sections) {
                let cards = ours.showsTypeHeadings ? ours.types.flatMap { $0.pieces.map(\.id) } : ours.pieces.map(\.id)
                #expect(cards == theirs.cards, "\(name): \(ours.name)")
                let types: [String] = ours.showsTypeHeadings ? ours.types.map(\.name) : []
                #expect(types == theirs.subs.map(\.type), "\(name): \(ours.name)")
                for (t, u) in zip(ours.types, theirs.subs) {
                    #expect(t.pieces.map(\.id) == u.cards, "\(name): \(ours.name) › \(t.name)")
                }
            }
            #expect(model.tiles == (snap.cutouts ?? []).map(\.v), "\(name): the tile row")
        }
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func shopAllShowsEveryPieceOnce() {
        let all = Browse.shopAll(SampleFiles.pieces)
        #expect(all.sections.map(\.name) == ["The Latest", "Women", "Men", "Jewelry & Objects"])
        #expect(all.sections[0].pieces.map(\.id) == Array(SampleFiles.pieces.filter(isPlaced).prefix(6).map(\.id)))
        let ids = all.sections.flatMap { $0.pieces.map(\.id) }
        #expect(ids.count == Set(ids).count)
        #expect(Set(ids) == Set(SampleFiles.pieces.filter(isPlaced).map(\.id)))
        #expect(all.tiles.isEmpty)
        #expect(all.showsSectionHeadings)
    }

    @Test func aDepartmentKeepsThePiecesTheLatestHasWhenItWouldBeEmptyWithout() {
        var a = Piece.stub("a"), b = Piece.stub("b")
        a.dept = .men; a.cat = "Shoes"; a.sub = "Sneakers"
        b.dept = .women; b.cat = "Handbags"; b.sub = "Totes"
        let all = Browse.shopAll([a, b])
        #expect(all.sections.map(\.name) == ["The Latest", "Women", "Men"])
        #expect(all.sections[1].pieces.map(\.id) == ["b"])
        #expect(all.sections[2].pieces.map(\.id) == ["a"])
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func aDepartmentIsItsCategoriesByType() {
        let women = Browse.department(.women, pieces: SampleFiles.pieces)
        #expect(!women.isCase)
        #expect(women.tiles == ["Handbags", "Clothing", "Shoes", "Accessories"])
        for s in women.sections {
            #expect(s.types.flatMap(\.pieces).count == s.pieces.count)
            let order = s.types.map { Taxonomy.subOrder[$0.name] ?? .max }
            #expect(order == order.sorted(), "\(s.name)'s types are in type order")
            for t in s.types {
                // Newest first within a type: the closet's own order.
                let at = t.pieces.map { p in SampleFiles.pieces.firstIndex(of: p)! }
                #expect(at == at.sorted())
            }
        }
        // A category with one type has no type heading (Men › Shoes is all Sneakers).
        let men = Browse.department(.men, pieces: SampleFiles.pieces)
        let shoes = men.sections.first { $0.name == "Shoes" }
        #expect(shoes?.showsTypeHeadings == false)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func jewelryAndObjectsIsACaseWhileItHasFewerThanTwelve() {
        let jo = Browse.department(.jewelry, pieces: SampleFiles.pieces)
        #expect(jo.isCase)
        #expect(jo.tiles.isEmpty)
        #expect(jo.sections.isEmpty)
        #expect(jo.casePieces.count == deptPieces(SampleFiles.pieces, .jewelry).count)
        #expect(jo.casePieces.allSatisfy { $0.story != nil })
        let (lead, rows) = Browse.caseLayout(jo.casePieces)
        #expect((lead != nil) == (jo.casePieces.count % 2 == 1))
        #expect(rows.allSatisfy { $0.count == 2 })
    }

    @Test func aCaseLeadsWithItsFeaturedPieceThenCategoryOrder() {
        func piece(_ id: String, _ cat: String, featured: Bool = false) -> Piece {
            var p = Piece.stub(id)
            p.dept = .jewelry; p.cat = cat; p.sub = "x"
            if featured { p.tags = ["Featured"] }
            return p
        }
        let list = [piece("w1", "Watches"), piece("h1", "Home", featured: true), piece("j1", "Jewelry"), piece("j2", "Jewelry")]
        #expect(Browse.caseOrder(list, cats: Dept.jewelry.categories).map(\.id) == ["h1", "j1", "j2", "w1"])
        let (lead, rows) = Browse.caseLayout(Array(Browse.caseOrder(list, cats: Dept.jewelry.categories).prefix(3)))
        #expect(lead?.id == "h1")
        #expect(rows.map { $0.map(\.id) } == [["j1", "j2"]])
        #expect(Browse.caseLayout(list).lead == nil)
    }

    @Test func atTwelvePiecesTheFullDepartmentComesBackByItself() {
        let twelve = (0..<12).map { i -> Piece in
            var p = Piece.stub("p\(i)")
            p.dept = .jewelry; p.cat = i < 6 ? "Jewelry" : "Art"; p.sub = i < 6 ? "Rings" : "Sculpture & Folk Art"
            return p
        }
        let page = Browse.department(.jewelry, pieces: twelve)
        #expect(!page.isCase)
        #expect(page.tiles == ["Jewelry", "Art"])
        #expect(Browse.department(.jewelry, pieces: Array(twelve.prefix(11))).isCase)
    }
}

@Suite("The photo size standard on cards")
struct CardPhotoFitTests {
    @Test func aRowDropsTheWhiteAboveItsTallestPieceDownToTheHeartsRoom() {
        let w: CGFloat = 193.5
        let full = w * 1.25
        // No measured top: the whole 4:5.
        #expect(CardPhotoFit.tileHeight(nil, width: w) == full)
        #expect(CardPhotoFit.tileHeight(PhotoFit(scale: 0.8, drop: 3, top: nil), width: w) == full)
        // A piece whose top sits 30% down: H − (H × .3 − 44).
        let t = CardPhotoFit.tileHeight(PhotoFit(scale: 0.8, drop: 3, top: 30), width: w)
        #expect(abs(t - (full - (full * 0.3 - 44))) < 0.001)
        // Near the top: nothing to drop.
        #expect(CardPhotoFit.tileHeight(PhotoFit(scale: 1, drop: 0, top: 10), width: w) == full)
        // A row shares the most any card needs.
        var a = Piece.stub("a"), b = Piece.stub("b")
        a.fit = PhotoFit(scale: 0.8, drop: 3, top: 30)
        b.fit = PhotoFit(scale: 0.9, drop: 2, top: 20)
        let row = CardPhotoFit.rowTileHeight([a, b], width: w)
        #expect(abs(row - (full - (full * 0.2 - 44))) < 0.001)
        b.fit = nil
        #expect(CardPhotoFit.rowTileHeight([a, b], width: w) == full)
    }

    @Test func widerThanAPhoneThePiecesSitSmallerAboutTheBaseline() {
        #expect(CardPhotoFit.factor(forWindowWidth: 440) == 1)
        #expect(CardPhotoFit.factor(forWindowWidth: 641) == 0.85)
        let fit = PhotoFit(scale: 0.9, drop: 4, top: 30)
        let phone = CardPhotoFit.transform(fit)!
        #expect(phone.scale == 0.9)
        #expect(abs(phone.drop - 0.04) < 1e-9)
        let wide = CardPhotoFit.transform(fit, factor: 0.85)!
        #expect(abs(wide.scale - 0.765) < 1e-9)
        #expect(abs(wide.drop - (4 * 0.85 + 44 * 0.15) / 100) < 1e-9)
        // The site's --cut with --fk: max(0, 125% × (.94 − fk × (.94 − top/100)) − 44px).
        let w: CGFloat = 300
        let cut = max(0, w * 1.25 * (0.94 - 0.85 * (0.94 - 0.3)) - 44)
        #expect(abs(CardPhotoFit.tileHeight(fit, width: w, factor: 0.85) - (w * 1.25 - cut)) < 0.001)
        #expect(CardPhotoFit.transform(nil) == nil)
    }
}
