import Foundation

// The product page's status beside the price (SPEC §10, "Price and status on one line"), ported from the site's
// app/lib/catalog/status.ts with the same names.

/// The two conditions a piece can be in (SPEC §10; Sam, November 2–3). A pre-owned piece can add its grade after it,
/// Like new or Excellent (Sam, November 3), a part of the condition, not a third one. status.ts `CONDITION`.
nonisolated enum Condition {
    static let new = "New with tags"
    static let used = "Pre-owned"
}

/// The piece's condition: "New with tags" (its tag, or a hangtag photo), otherwise "Pre-owned". status.ts `conditionOf`.
nonisolated func conditionOf(newWithTags: Bool) -> String {
    newWithTags ? Condition.new : Condition.used
}

/// One mark of the status line. The condition carries a pre-owned piece's grade, which the page sets after it in the
/// same type, a hairline between them instead of the middle dot: "Pre-owned | Like new". status.ts `StatusMark`.
nonisolated struct StatusMark: Hashable, Sendable {
    var text: String
    var grade: Grade? = nil
}

/// What the status line reads from a piece (status.ts `Status`).
nonisolated struct StatusFacts: Sendable {
    var authenticated = false
    var tags: [String] = []
    /// The piece's detail line ("Vintage 1980s · Red"): its first part gives a vintage piece's era.
    var detail = ""
    var newWithTags = false
    var grade: Grade? = nil
    var sizes: [String] = []
    /// The US size a label in another system converts to ("US 6").
    var fnote: String? = nil
}

nonisolated extension StatusFacts {
    init(_ p: ProductDetail) {
        self.init(
            authenticated: p.authenticated, tags: p.tags, detail: p.detail, newWithTags: p.newWithTags, grade: p.grade,
            sizes: p.sizes, fnote: p.fnote)
    }
}

/// The product page's status, said quietly beside the price (SPEC §10). The size leads when the piece has one (Sam,
/// November 3), a label in another system with its US size after it ("Size FR 38 (US 6)"); then, in this order,
/// Authenticated, Vintage (with its era when the record gives one, "Vintage 1980s") and the condition, which every piece
/// states (New with tags or Pre-owned), with a pre-owned piece's grade (never for New with tags). No "One of one":
/// every piece is, so it says nothing. status.ts `statusMarks`.
nonisolated func statusMarks(_ p: StatusFacts) -> [StatusMark] {
    let era = p.detail.components(separatedBy: " · ")[0]
    let size = sizeWords(p.sizes)
    var marks: [StatusMark] = []
    if !size.isEmpty { marks.append(StatusMark(text: size + ((p.fnote ?? "").isEmpty ? "" : " (\(p.fnote!))"))) }
    if p.authenticated { marks.append(StatusMark(text: "Authenticated")) }
    if p.tags.contains("Vintage") { marks.append(StatusMark(text: era.hasPrefix("Vintage") ? era : "Vintage")) }
    marks.append(StatusMark(text: conditionOf(newWithTags: p.newWithTags), grade: p.newWithTags ? nil : p.grade))
    return marks
}

/// The status line in words, as the page's text reads and a screen reader says it (a real space before the grade, so
/// it's two words): "Size 10 · Vintage · Pre-owned Excellent". status.ts `statusLine`.
nonisolated func statusLine(_ p: StatusFacts) -> String {
    statusMarks(p).map { m in m.grade.map { "\(m.text) \($0.rawValue)" } ?? m.text }.joined(separator: " · ")
}
