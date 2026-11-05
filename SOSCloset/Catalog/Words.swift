import Foundation

// Prices, sizes and counts in words, and photos at the width the screen needs, ported from the site's
// app/lib/browse/text.ts (dollars, money, money2, plural), app/lib/browse/sizes.ts (sizeOrder, sizeWords) and
// app/components/Img.tsx (Shopify's image service, asked for a width).

/// A whole number with en-US grouping: 2600 → "2,600".
nonisolated func groupedDigits(_ n: Int64) -> String {
    let digits = String(n.magnitude)
    var out = ""
    for (i, ch) in digits.enumerated() {
        if i > 0 && (digits.count - i) % 3 == 0 { out.append(",") }
        out.append(ch)
    }
    return (n < 0 ? "-" : "") + out
}

/// A price that can be written (a price Shopify sent that wasn't a number shows as nothing, never stops the app).
private nonisolated func isPrice(_ n: Double) -> Bool { n.isFinite && abs(n) < 1e15 }

/// Whole dollars, rounded up (Sam's rule for the home page, SPEC §11a): $649.14 → "$650", $229.99 → "$230", $2,600 →
/// "$2,600". Counted in cents first, so a sum that comes out a hair over a dollar isn't rounded up. text.ts `dollars`.
nonisolated func priceText(_ price: Double) -> String {
    guard isPrice(price) else { return "" }
    return "$" + groupedDigits(Int64((jsRound(price * 100) / 100).rounded(.up)))
}

/// "$1,775", or with its cents when a price has them: "$204.75" (never rounded). What the site's cards and product page
/// show. text.ts `money`.
nonisolated func moneyText(_ price: Double) -> String {
    guard isPrice(price) else { return "" }
    return jsRound(price * 100).truncatingRemainder(dividingBy: 100) != 0
        ? centsText(price) : "$" + groupedDigits(Int64(jsRound(price)))
}

/// Always with the cents: "$1,775.00" (the bag). text.ts `money2`.
nonisolated func centsText(_ price: Double) -> String {
    guard isPrice(price) else { return "" }
    let cents = Int64(jsRound(price * 100))
    let c = cents.magnitude % 100
    return (cents < 0 ? "-$" : "$") + groupedDigits(Int64(cents.magnitude / 100)) + "." + (c < 10 ? "0" : "") + String(c)
}

/// "117 pieces", "1 piece" (text.ts `plural`; the home page's View all credit).
nonisolated func plural(_ n: Int, _ one: String, _ many: String? = nil) -> String {
    "\(n) \(n == 1 ? one : many ?? one + "s")"
}

nonisolated enum SizeWords {
    static let letters = ["XXS", "XS", "S", "M", "L", "XL", "XXL"]
    static let plainNumber = JSRegex(#"^\d+(\.\d+)?$"#)
    static let notNumber = JSRegex(#"[^0-9.]"#)
}

/// Within a size group: letters (XS…XL), then plain numbers, then the rest (W25, FR 40, IT 42, 40R…).
/// sizes.ts `sizeOrder`, as a sort's "comes first".
nonisolated func sizeComesFirst(_ a: String, _ b: String) -> Bool {
    func rank(_ z: String) -> (Int, Double) {
        if let i = SizeWords.letters.firstIndex(of: z) { return (0, Double(i)) }
        if SizeWords.plainNumber.test(z) { return (1, jsParseFloat(z)) }
        let n = jsParseFloat(SizeWords.notNumber.replaceAll(z, with: ""))
        return (2, n.isNaN ? 0 : n)
    }
    let u = rank(a)
    let v = rank(b)
    if u.0 != v.0 { return u.0 < v.0 }
    if u.1 != v.1 { return u.1 < v.1 }
    return a.compare(b, locale: Locale(identifier: "en")) == .orderedAscending
}

/// Sizes in words: "Size S", "Sizes 8, 10", in size order. On a card (`range: true`), three or more read as a range
/// so the price line stays one line: "Sizes XS–L" (SPEC §7, Card text). Empty when the piece has no size.
/// sizes.ts `sizeWords`.
nonisolated func sizeWords(_ sizes: [String], range: Bool = false) -> String {
    guard !sizes.isEmpty else { return "" }
    let z = sizes.stableSorted(by: sizeComesFirst)
    let list = range && z.count > 2 ? "\(z[0])–\(z[z.count - 1])" : z.joined(separator: ", ")
    return "\(z.count > 1 ? "Sizes" : "Size") \(list)"
}

// MARK: Photos at the width the screen needs (APP-SPEC §3.1, Images)

nonisolated enum ImageWidths {
    /// The widths the site offers the browser from Shopify's image service (Img.tsx `WIDTHS`).
    static let steps = [240, 360, 480, 640, 800, 1000, 1200]
}

/// A photo at `width` pixels: Shopify's image service resizes on request (`?width=`, as the site asks it); any other
/// address (the sample store's files) comes back as it is. The file in Shopify is never changed.
nonisolated func sizedImageURL(_ url: URL, width: Int) -> URL {
    guard url.absoluteString.hasPrefix("https://cdn.shopify.com/"),
        var parts = URLComponents(url: url, resolvingAgainstBaseURL: false)
    else { return url }
    var items = (parts.queryItems ?? []).filter { $0.name != "width" }
    items.append(URLQueryItem(name: "width", value: String(width)))
    parts.queryItems = items
    return parts.url ?? url
}

/// The width to ask for, to fill `pixels` (the frame's points × the screen's scale): the site's smallest step that
/// covers it, never wider than the photo itself (`max`, its own width when known), so the same few sizes are asked for
/// everywhere and stay in the cache.
nonisolated func imageWidth(forPixels pixels: Double, max: Int?) -> Int {
    let steps = ImageWidths.steps.filter { max == nil || $0 <= max! }
    guard let last = steps.last else { return max ?? ImageWidths.steps.last! }
    return steps.first { Double($0) >= pixels } ?? last
}

nonisolated extension PieceImage {
    /// This photo at the width a frame `points` wide needs on a screen of `scale` (`sizedImageURL`).
    func url(points: Double, scale: Double) -> URL {
        sizedImageURL(url, width: imageWidth(forPixels: points * scale, max: width))
    }
}
