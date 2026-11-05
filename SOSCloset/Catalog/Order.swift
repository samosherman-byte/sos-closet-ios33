import Foundation

// The closet's order and the closet itself, ported from the site's app/lib/catalog/order.ts and closet.ts, with the
// two small pieces of app/lib/browse/pages.ts they need (deptPieces, isCaseDept).

/// A piece with what the order needs (order.ts `OrderInput`).
nonisolated struct OrderInput: Sendable {
    var piece: Piece
    var createdAt: String
    /// Handle of the piece to show this one right after (the custom.place_after metafield).
    var placeAfter: String?
}

/// Newest first. Pieces listed after the import sort by their own created date, ahead of the imported pieces, which
/// keep the prototype's order (the import gives them all the same date). Then the hold-backs: a held-back piece moves
/// to just after the piece named, without changing its date (SPEC §7). order.ts `orderPieces`.
nonisolated func orderPieces(_ input: [OrderInput]) -> [Piece] {
    let index = LegacyOrder.index
    let fresh = input.filter { index[$0.piece.id] == nil }.stableSorted { $0.createdAt > $1.createdAt }
    let legacy = input.filter { index[$0.piece.id] != nil }.stableSorted { index[$0.piece.id]! < index[$1.piece.id]! }
    let list = (fresh + legacy).map(\.piece)

    // The store's own setting wins; the settings file's list only applies until any piece has one.
    let byHandle = Dictionary(list.map { ($0.handle, $0.id) }, uniquingKeysWith: { _, last in last })
    let set = input.filter { $0.placeAfter.map { byHandle[$0] != nil } ?? false }
    let rules = set.isEmpty ? Merch.holdBack : set.map { (id: $0.piece.id, after: byHandle[$0.placeAfter!]!) }
    return holdBack(list, rules)
}

/// Moves each held-back piece to just after the one it names (staying where it was when that one isn't there).
/// order.ts `holdBack`.
nonisolated func holdBack(_ list: [Piece], _ rules: [(id: String, after: String)]) -> [Piece] {
    var out = list
    for (id, after) in rules {
        guard let i = out.firstIndex(where: { $0.id == id }) else { continue }
        let p = out.remove(at: i)
        let j = out.firstIndex { $0.id == after }
        out.insert(p, at: j.map { $0 + 1 } ?? i)
    }
    return out
}

/// Pieces with their structure tags: the ones department sections can place (pages.ts `placed`).
nonisolated func isPlaced(_ p: Piece) -> Bool {
    p.dept != nil && !(p.cat ?? "").isEmpty && !(p.sub ?? "").isEmpty
}

/// A department's pieces: the ones its page shows (pages.ts `deptPieces`).
nonisolated func deptPieces(_ pieces: [Piece], _ dept: Dept) -> [Piece] {
    pieces.filter { $0.dept == dept && isPlaced($0) }
}

/// Whether a department is a small case (SPEC §7, "A small department is a case"): fewer than `Merch.caseMax` pieces.
/// Counted on the whole department, so narrowing it never turns it back into a full one. pages.ts `isCaseDept`.
nonisolated func isCaseDept(_ pieces: [Piece], _ dept: Dept) -> Bool {
    deptPieces(pieces, dept).count < Merch.caseMax
}

/// The closet from Shopify's products (or the sample store's): every piece for sale, newest first, hold-backs applied,
/// and, in a small department's case (SPEC §7), each piece's story line. (Only there: a full department's cards have
/// no story line.) closet.ts `closetOf`.
nonisolated func closetOf(_ records: [ProductRecord]) -> [Piece] {
    var pieces = orderPieces(
        records.compactMap { r in
            toPiece(r).map { OrderInput(piece: $0, createdAt: r.createdAt, placeAfter: r.metafields.placeAfter) }
        })
    let byHandle = Dictionary(records.map { ($0.handle, $0) }, uniquingKeysWith: { _, last in last })
    for d in Dept.allCases where isCaseDept(pieces, d) {
        for i in pieces.indices where pieces[i].dept == d && isPlaced(pieces[i]) {
            let story = byHandle[pieces[i].handle].map(storyOf) ?? ""
            if !story.isEmpty { pieces[i].story = story }
        }
    }
    return pieces
}
