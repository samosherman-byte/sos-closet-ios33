import Foundation

// What Shop All and the departments show, ported from the site's app/lib/browse/pages.ts and derive.ts (SPEC §7;
// APP-SPEC §3.2): Shop All is The Latest and then each department; a department is its categories in the tile row's
// order, each organized by type; a small department is a case. Phase 1 has no filters (APP-SPEC §2), so a page shows
// every piece it has, in the closet's order.

/// A section of a Shop page under its heading (derive.ts `Section`).
nonisolated struct BrowseSection: Hashable, Sendable, Identifiable {
    enum Kind: Hashable, Sendable {
        /// Shop All's The Latest: the six newest.
        case latest
        /// A department on Shop All: its heading opens the department.
        case dept(Dept)
        /// A category on a department page.
        case cat
    }

    var name: String
    var kind: Kind
    var pieces: [Piece]
    /// A department's category: its types in type order (`Taxonomy.subs`), each with its pieces. Empty on Shop All.
    var types: [TypeGroup] = []

    var id: String { name }
    /// A category with one type has no type heading (SPEC §7): its pieces are one grid.
    var showsTypeHeadings: Bool { types.count > 1 }
}

/// A type inside a category (derive.ts `TypeSection`).
nonisolated struct TypeGroup: Hashable, Sendable, Identifiable {
    var name: String
    var pieces: [Piece]
    var id: String { name }
}

/// A Shop page: Shop All, a department, or a small department's case.
nonisolated struct ShopPageModel: Hashable, Sendable {
    var dept: Dept?
    /// Headings while more than one section is left (derive.ts `sectioned`); one section shows its type headings alone.
    var sections: [BrowseSection]
    /// A case's pieces in its order (SPEC §7): the first leads on a row of its own when the count is odd.
    var casePieces: [Piece]
    var isCase: Bool

    /// The tile row: a full department's categories that have pieces, in its order. None on Shop All or in a case.
    var tiles: [String] {
        guard dept != nil, !isCase else { return [] }
        return sections.map(\.name)
    }

    /// Category headings show while the page has more than one section (SPEC §7: "with only one section left, no
    /// headings, just the grid").
    var showsSectionHeadings: Bool { sections.count > 1 }

    var isEmpty: Bool { sections.isEmpty && casePieces.isEmpty }

    /// The page's outline for the place line and the compact tile row: each section's name and its type headings.
    var outline: [(section: String, types: [String])] {
        sections.map { s in (s.name, s.showsTypeHeadings ? s.types.map(\.name) : []) }
    }
}

nonisolated enum Browse {
    /// The Latest on Shop All: the six newest, three rows of two on phones (derive.ts `LATEST`).
    static let latestCount = 6
    /// The Latest is drawn from the newest this many (derive.ts `NEWEST`).
    static let newest = 24

    /// The page for a place on the map, from the closet (every piece for sale, in its order).
    static func page(_ place: ShopPlace, pieces: [Piece]) -> ShopPageModel {
        switch place {
        case .all: shopAll(pieces)
        case .women: department(.women, pieces: pieces)
        case .men: department(.men, pieces: pieces)
        case .jewelry: department(.jewelry, pieces: pieces)
        }
    }

    /// Shop All (derive.ts, `def.key === 'shop'`): The Latest, then each department with the rest, so every piece shows
    /// once; a department keeps the pieces The Latest has when it would be empty without them.
    static func shopAll(_ pieces: [Piece]) -> ShopPageModel {
        let base = pieces.filter(isPlaced)
        let newest = Set(base.prefix(newest).map(\.id))
        let fresh = base.filter { newest.contains($0.id) }
        let latest = Array(fresh.prefix(latestCount))
        let inLatest = Set(latest.map(\.id))
        var sections: [BrowseSection] = []
        if !latest.isEmpty {
            sections.append(BrowseSection(name: "The Latest", kind: .latest, pieces: latest))
        }
        for dept in Dept.allCases {
            let its = base.filter { $0.dept == dept }
            guard !its.isEmpty else { continue }
            let rest = its.filter { !inLatest.contains($0.id) }
            sections.append(BrowseSection(name: dept.displayName, kind: .dept(dept), pieces: rest.isEmpty ? its : rest))
        }
        return ShopPageModel(dept: nil, sections: sections, casePieces: [], isCase: false)
    }

    /// A department (derive.ts, `deptPage`): each category in the tile row's order, then its types in type order, every
    /// piece; empty sections don't appear. Under `Merch.caseMax` pieces it's a case instead (pages.ts `isCase`).
    static func department(_ dept: Dept, pieces: [Piece]) -> ShopPageModel {
        let base = deptPieces(pieces, dept)
        if base.count < Merch.caseMax {
            return ShopPageModel(dept: dept, sections: [], casePieces: caseOrder(base, cats: dept.categories), isCase: true)
        }
        var sections: [BrowseSection] = []
        for cat in dept.categories {
            let its = base.filter { $0.cat == cat }
            guard !its.isEmpty else { continue }
            var order = Taxonomy.subs.filter { t in its.contains { $0.sub == t } }
            for p in its { if let s = p.sub, !order.contains(s) { order.append(s) } }
            sections.append(BrowseSection(
                name: cat, kind: .cat, pieces: its,
                types: order.map { t in TypeGroup(name: t, pieces: its.filter { $0.sub == t }) }))
        }
        return ShopPageModel(dept: dept, sections: sections, casePieces: [], isCase: false)
    }

    /// The piece tagged to lead a case (derive.ts `isFeatured`).
    static func isFeatured(_ p: Piece) -> Bool {
        p.tags.contains { $0.lowercased() == Merch.featuredTag }
    }

    /// A case's order (derive.ts `caseOrder`): the department's category order, newest first within each, with a
    /// featured piece first.
    static func caseOrder(_ list: [Piece], cats: [String]) -> [Piece] {
        var out: [Piece] = []
        for c in cats { for p in list where p.cat == c { out.append(p) } }
        for p in list where !out.contains(p) { out.append(p) }
        return out.filter(isFeatured) + out.filter { !isFeatured($0) }
    }

    /// Pairs for a two-across grid: each row's pieces, two at a time (the last row may hold one).
    static func rows(_ pieces: [Piece]) -> [[Piece]] {
        stride(from: 0, to: pieces.count, by: 2).map { Array(pieces[$0..<min($0 + 2, pieces.count)]) }
    }

    /// A case's layout (SPEC §7): with an odd count, the first piece leads on a row of its own; the rest in pairs.
    static func caseLayout(_ pieces: [Piece]) -> (lead: Piece?, rows: [[Piece]]) {
        guard pieces.count % 2 == 1, let first = pieces.first else { return (nil, rows(pieces)) }
        return (first, rows(Array(pieces.dropFirst())))
    }
}

// MARK: - The photo size standard on a card (SPEC §7, §12; APP-SPEC §3.3)

nonisolated enum CardPhotoFit {
    /// The room the heart needs at the top of a tile: a row keeps this much white above its tallest piece.
    static let heartRoom: CGFloat = 44
    /// Wider than a phone (an unfolded iPhone Duo) the pieces sit 15% smaller, about the baseline (the site's `--fk`).
    static let wideFactor = 0.85

    /// `--fk`: 1 up to the phone layout's widest window, 0.85 wider.
    static func factor(forWindowWidth width: CGFloat) -> Double {
        width <= Layout.phoneMaxWidth ? 1 : wideFactor
    }

    /// A card's tile height for its photo's numbers: its full 4:5 height minus the white above its piece beyond the
    /// heart's room (the site's `--cut`: `max(0, 125% × (.94 − fk × (.94 − top/100)) − 44px)`). A card with no
    /// measured top needs the whole 4:5.
    static func tileHeight(_ fit: PhotoFit?, width: CGFloat, factor fk: Double = 1) -> CGFloat {
        let full = width * 1.25
        guard let top = fit?.top else { return full }
        let cut = max(0, full * (0.94 - fk * (0.94 - top / 100)) - heartRoom)
        return full - cut
    }

    /// A row's shared tile height: the most any of its cards needs, so every photo keeps its size and its place on the
    /// baseline and the words stay level along the row.
    static func rowTileHeight(_ pieces: [Piece], width: CGFloat, factor fk: Double = 1) -> CGFloat {
        pieces.map { tileHeight($0.fit, width: width, factor: fk) }.max() ?? width * 1.25
    }

    /// How the cover sits in its 4:5 frame: scaled about its centre, then moved down by a share of its own height (the
    /// site's `translateY(drop × fk + 44% × (1 − fk)) scale(scale × fk)`). Nil without numbers: the photo as it is.
    static func transform(_ fit: PhotoFit?, factor fk: Double = 1) -> (scale: Double, drop: Double)? {
        guard let fit else { return nil }
        return (fit.scale * fk, (fit.drop * fk + 44 * (1 - fk)) / 100)
    }
}
