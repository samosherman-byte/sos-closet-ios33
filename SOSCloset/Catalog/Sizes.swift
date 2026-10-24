import Foundation

/// Sizes in words, ported from the site's `app/lib/browse/sizes.ts`.
nonisolated enum Sizes {
    private static let letters = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]

    /// Within a size group: letters (XS…XL), then plain numbers, then the rest (W25, FR 40, IT 42, 40R…).
    static func areInOrder(_ a: String, _ b: String) -> Bool {
        func rank(_ size: String) -> (Int, Double) {
            if let index = letters.firstIndex(of: size) { return (0, Double(index)) }
            if size.wholeMatch(of: /\d+(\.\d+)?/) != nil, let number = Double(size) { return (1, number) }
            return (2, Double(size.filter { $0.isNumber || $0 == "." }) ?? 0)
        }
        let (u, v) = (rank(a), rank(b))
        if u.0 != v.0 { return u.0 < v.0 }
        if u.1 != v.1 { return u.1 < v.1 }
        return a.localizedCompare(b) == .orderedAscending
    }

    /// "Size S", "Sizes 8, 10", in size order. On a card (`range`), three or more read as a range so the price line
    /// stays one line: "Sizes XS–L" (SPEC §7, Card text). Empty when the piece has no size.
    static func words(_ sizes: [String], range: Bool = false) -> String {
        guard !sizes.isEmpty else { return "" }
        let sorted = sizes.sorted(by: areInOrder)
        let list = range && sorted.count > 2 ? "\(sorted[0])–\(sorted[sorted.count - 1])" : sorted.joined(separator: ", ")
        return "\(sorted.count > 1 ? "Sizes" : "Size") \(list)"
    }
}
