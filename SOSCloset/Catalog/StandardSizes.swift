import Foundation

// Standard sizes (SPEC §9; Sam, November 1: "keep the label size for display, add a standard size behind it"),
// ported from the site's app/lib/browse/std-sizes.ts: axisOf(), stdOf() and fitOf(), unchanged. The label's size stays
// on the piece; behind it is the size it fits on one scale, so a US 4, an FR 36 and a W27 all answer to S. Each piece
// has one scale (its axis). (My sizes, the rest of that file, comes with Search in phase 2.)

/// A size scale (std-sizes.ts `Axis`).
nonisolated enum Axis: String, CaseIterable, Sendable, Hashable {
    /// Women's clothing: XXS–XXL, from US 00–18, jeans waists, and FR, IT, DE and UK sizes.
    case wc
    /// Women's shoes: US sizes, from EU/IT (less 30) and UK (plus 2).
    case ws
    /// Men's clothing: XS–XXL, from letters, shirt collars, waists and IT/EU chest sizes.
    case mc
    /// Men's jackets and suits: the chest size itself (40R…), since tailoring is bought by chest.
    case mt
    /// Men's shoes: US sizes, from UK (plus 1) and EU (less 33).
    case ms
}

/// What the size rules read of a piece (std-sizes.ts `SizedPiece`).
nonisolated struct SizedPiece: Sendable {
    var dept: Dept?
    var cat: String?
    var sub: String?
    var designer: String
}

nonisolated enum StandardSizes {
    static let letters = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]
    /// US 00, 0, 2, 4 … 18
    static let wStep = ["XXS", "XS", "XS", "S", "S", "M", "M", "L", "L", "XL", "XXL"]
    /// Plain European sizes are Italian unless the house sizes otherwise.
    static let wRegion: [String: String] = ["Escada": "DE", "Barbara Lohmann": "DE"]

    static let system = JSRegex(#"^(FR|EU|IT|DE|UK|US|W)\s?(\d+(?:\.\d+)?)$"#, ignoreCase: true)
    static let bare = JSRegex(#"^\d+(\.\d+)?$"#)
    static let oneSize = JSRegex(#"^one ?size$"#, ignoreCase: true)
    static let chest = JSRegex(#"^(\d{2})([SRL])?$"#)

    static func wFromUS(_ us: Double) -> String {
        // (Only ever called with a number; the guard keeps a stray NaN from stopping the app.)
        guard us.isFinite else { return "" }
        return us < 0 ? "XXS" : wStep[Int(min(10, (us / 2).rounded(.down) + 1))]
    }

    static func mFromChest(_ c: Double) -> String {
        c <= 35 ? "XS" : c <= 38 ? "S" : c <= 41 ? "M" : c <= 44 ? "L" : c <= 47 ? "XL" : "XXL"
    }

    static func letterOf(_ z: String) -> [String]? {
        var u = z.uppercased()
        if u == "2XL" || u == "3XL" || u == "4XL" || u == "5XL" || u == "XXXL" { u = "XXL" }
        if u == "MP" || u == "M/P" { return ["M"] }
        let parts = u.components(separatedBy: "/")
        let out = parts.filter { letters.contains($0) }
        return out.count == parts.count ? out : nil
    }
}

/// The piece's scale (nil = it has none: handbags, jewelry, accessories, art). std-sizes.ts `axisOf`.
nonisolated func axisOf(_ x: SizedPiece) -> Axis? {
    switch x.dept {
    case .women:
        return x.cat == "Clothing" ? .wc : x.cat == "Shoes" ? .ws : nil
    case .men:
        if x.cat == "Clothing" { return x.sub == "Suits" || x.sub == "Sport Coats & Blazers" ? .mt : .mc }
        return x.cat == "Shoes" ? .ms : nil
    default:
        return nil
    }
}

/// The standard sizes a label size `z0` fits on the piece's scale, and the US size to show beside the label when it's
/// in another system ("US 6"; "" when there's nothing to add). `fromSearch`: a bare number typed in search only means
/// something where numbers are the scale itself. std-sizes.ts `stdOf`, line for line.
nonisolated func stdOf(_ x: SizedPiece, _ z0: String, axis: Axis? = nil, fromSearch: Bool = false) -> ([String], String) {
    let S = StandardSizes.self
    let z = z0.jsTrimmed
    guard let ax = axis ?? axisOf(x), !S.oneSize.test(z) else { return ([], "") }
    let m = S.system.groups(z)
    let sys = m?[1]?.uppercased() ?? ""
    let n = m.map { jsParseFloat($0[2] ?? "") } ?? jsParseFloat(z)
    let bare = m == nil && S.bare.test(z)
    let L = S.letterOf(z)
    let num = jsNumberText

    switch ax {
    case .wc:
        if let L { return (L, "") }
        if z == "00" { return (["XXS"], "") }
        if sys == "W" || (bare && n >= 24 && n <= 34 && x.sub == "Pants & Jeans" && !fromSearch) {
            let us = n <= 24 ? -1 : (n - 25) * 2
            return ([S.wFromUS(us)], "US " + (us < 0 ? "00" : num(us)))
        }
        if sys == "US" || (bare && n <= 18) { return ([S.wFromUS(n)], "") }
        if !sys.isEmpty || (bare && n >= 32 && n <= 52 && !fromSearch) {
            let r = !sys.isEmpty ? sys : S.wRegion[x.designer] ?? "IT"
            let u2 = r == "FR" || r == "EU" ? n - 32 : r == "DE" ? n - 30 : r == "UK" ? n - 4 : n - 36
            return ([S.wFromUS(u2)], "US " + num(u2))
        }
        return ([], "")
    case .ws, .ms:
        let w = ax == .ws
        if sys == "UK" {
            let a = n + (w ? 2 : 1)
            return ([num(a)], "US " + num(a))
        }
        if sys == "US" || (bare && n < 16) { return ([num(n)], "") }
        if sys == "EU" || sys == "IT" || sys == "FR" || (bare && n >= 33 && n <= 50) {
            let e = n - (w ? 30 : 33)
            return ([num(e)], "US " + num(e))
        }
        return ([], "")
    case .mt:
        if let t = S.chest.groups(z.uppercased()) { return ([(t[1] ?? "") + (t[2] ?? "R")], "") }
        if sys == "IT" || sys == "EU" { return ([num(n - 10) + "R"], "US " + num(n - 10) + "R") }
        return ([], "")
    case .mc:
        if let L { return (L.filter { $0 != "XXS" }, "") }
        if sys == "IT" || sys == "EU" { return ([S.mFromChest(n - 10)], S.mFromChest(n - 10)) }
        if fromSearch { return ([], "") }
        if bare && (x.sub == "Dress Shirts" || (n >= 14 && n <= 18.5 && n.truncatingRemainder(dividingBy: 1) != 0)) {
            return ([n < 15 ? "S" : n < 16 ? "M" : n < 17 ? "L" : n < 18 ? "XL" : "XXL"], "")
        }
        if sys == "W" || (bare && (x.sub == "Shorts" || x.sub == "Pants & Jeans")) {
            return ([n <= 28 ? "XS" : n <= 31 ? "S" : n <= 33 ? "M" : n <= 36 ? "L" : n <= 39 ? "XL" : "XXL"], "")
        }
        if bare && n >= 34 && n <= 52 { return ([S.mFromChest(n)], "") }
        return ([], "")
    }
}

/// A piece's scale, the standard sizes it fits (`fz`), and the US size its label converts to (`fnote`, only for a
/// piece in one size). `sizes` are its label sizes ("S/M" already split). std-sizes.ts `fitOf`.
nonisolated func fitOf(_ x: SizedPiece, _ sizes: [String]) -> (ax: Axis?, fz: [String], fnote: String) {
    let ax = axisOf(x)
    var fz: [String] = []
    var fnote = ""
    for z in sizes {
        let r = stdOf(x, z, axis: ax, fromSearch: false)
        for s in r.0 where !fz.contains(s) { fz.append(s) }
        if !r.1.isEmpty && sizes.count == 1 { fnote = r.1 }
    }
    return (ax, fz, fnote)
}
