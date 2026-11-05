import Foundation

// The closet's structure: departments, their categories, the type order, "Show only" options, price ranges and
// colors. Ported from the site's app/settings/taxonomy.ts (itself copied from data/catalog.json → cfg).
// Jewelry & Objects (Sam, November 1; SPEC §2): Jewelry & Watches and Art & Home are one department, key `jewelry`.
// Nothing in Shopify is retagged: a piece tagged dept:jewelry or dept:home belongs to it (`Taxonomy.deptTag`).

/// A department (taxonomy.ts `Dept`), in the tab row's order.
nonisolated enum Dept: String, CaseIterable, Sendable, Hashable, Codable {
    case women, men, jewelry

    /// Its name (taxonomy.ts `DEPT_NAME`): "Women", "Men", "Jewelry & Objects".
    var displayName: String {
        switch self {
        case .women: "Women"
        case .men: "Men"
        case .jewelry: "Jewelry & Objects"
        }
    }

    /// Its place on the tab map (SPEC §1.1): Shop All is 0, then Women 1, Men 2, Jewelry & Objects 3. Moving between
    /// departments goes sideways toward the higher or lower number.
    var tabIndex: Int {
        switch self {
        case .women: 1
        case .men: 2
        case .jewelry: 3
        }
    }

    /// Its categories in the tile row's order (taxonomy.ts `CATS[dept]`; each category's key and label are the same).
    var categories: [String] { Taxonomy.cats[self] ?? [] }
}

nonisolated enum Taxonomy {
    /// The department each dept: tag names (taxonomy.ts `DEPT_TAG`): dept:home (Art & Home until November 1) is
    /// Jewelry & Objects too.
    static let deptTag: [String: Dept] = [
        "women": .women,
        "men": .men,
        "jewelry": .jewelry,
        "home": .jewelry,
    ]

    /// Each department's categories, in the tile row's order (taxonomy.ts `CATS`; on the site each is a [key, label]
    /// pair, and the two are the same for every category).
    static let cats: [Dept: [String]] = [
        .women: ["Handbags", "Clothing", "Shoes", "Accessories"],
        .men: ["Clothing", "Shoes", "Accessories"],
        .jewelry: ["Jewelry", "Watches", "Art", "Home"],
    ]

    /// Every type, in the order sections and Search list them (taxonomy.ts `SUBS`).
    static let subs: [String] = [
        "Top-Handle",
        "Shoulder Bags",
        "Crossbody",
        "Totes",
        "Clutches & Evening",
        "Backpacks",
        "Dresses",
        "Tops & Blouses",
        "Knitwear",
        "Jackets & Coats",
        "Blazers & Suiting",
        "Suits",
        "Sport Coats & Blazers",
        "Dress Shirts",
        "Casual Shirts",
        "Polos",
        "Sweatshirts & Hoodies",
        "Pants & Jeans",
        "Skirts & Shorts",
        "Shorts",
        "Heels & Pumps",
        "Flats & Loafers",
        "Sandals & Slides",
        "Boots & Booties",
        "Sneakers",
        "Small Leather Goods",
        "Sunglasses",
        "Belts",
        "Scarves & Hats",
        "Necklaces & Pendants",
        "Bracelets",
        "Rings",
        "Earrings",
        "Women’s Watches",
        "Men’s Watches",
        "Ceramics & Porcelain",
        "Glass & Crystal",
        "Decorative Objects",
        "Tableware",
        "Prints & Paintings",
        "Sculpture & Folk Art",
        "Animation & Collectible Art",
    ]

    /// Where a type sorts (its place in `subs`), for sections organized by type.
    static let subOrder: [String: Int] = Dictionary(uniqueKeysWithValues: subs.enumerated().map { ($1, $0) })

    /// "Show only" options on Shop All and other all-department pages (taxonomy.ts `SHOW_ONLY.new`).
    static let showOnlyAll: [String] = ["Vintage"]
    /// "Show only" options on each department (taxonomy.ts `SHOW_ONLY`).
    static let showOnly: [Dept: [String]] = [
        .women: ["Vintage"],
        .men: ["Vintage"],
        .jewelry: ["Women’s", "Men’s", "Fine", "Fashion", "Mid-Century", "Signed", "Vintage & Antique"],
    ]

    /// Categories that carry sizes (taxonomy.ts `SIZED`).
    static let sized: Set<String> = ["Clothing", "Shoes"]

    /// A price range (taxonomy.ts `PriceRange`): `lo` inclusive, `hi` exclusive, in dollars.
    nonisolated struct PriceRange: Hashable, Sendable {
        var key: String
        var label: String
        var lo: Double
        var hi: Double
    }

    /// taxonomy.ts `PRICES`
    static let prices: [PriceRange] = [
        PriceRange(key: "a", label: "Under $250", lo: 0, hi: 250),
        PriceRange(key: "b", label: "$250 – $500", lo: 250, hi: 500),
        PriceRange(key: "c", label: "$500 – $1,000", lo: 500, hi: 1000),
        PriceRange(key: "d", label: "$1,000 and up", lo: 1000, hi: 1_000_000),
    ]

    /// A color group (taxonomy.ts `COLORS`): its key (the color: tag), its name, and the site's CSS background for
    /// its swatch (Gold and Silver are metallic gradients, Prints & Multi a four-color tile).
    nonisolated struct ColorGroup: Hashable, Sendable {
        var key: String
        var name: String
        var css: String
    }

    /// taxonomy.ts `COLORS`
    static let colors: [ColorGroup] = [
        ColorGroup(key: "black", name: "Black", css: "#111111"),
        ColorGroup(key: "white", name: "White & Cream", css: "#F5F1E8"),
        ColorGroup(key: "gray", name: "Gray", css: "#9B9B97"),
        ColorGroup(key: "brown", name: "Brown & Tan", css: "#8A5A3B"),
        ColorGroup(key: "beige", name: "Beige", css: "#D9C7A7"),
        ColorGroup(key: "red", name: "Red", css: "#A8232E"),
        ColorGroup(key: "pink", name: "Pink", css: "#E7A1B6"),
        ColorGroup(key: "orange", name: "Orange", css: "#D8692A"),
        ColorGroup(key: "yellow", name: "Yellow", css: "#E5C24A"),
        ColorGroup(key: "green", name: "Green", css: "#3F6B4A"),
        ColorGroup(key: "blue", name: "Blue", css: "#2C4F8E"),
        ColorGroup(key: "purple", name: "Purple", css: "#6C3E78"),
        ColorGroup(key: "gold", name: "Gold", css: "linear-gradient(135deg,#8C6A1F,#E8CF7A 45%,#A9822E)"),
        ColorGroup(key: "silver", name: "Silver", css: "linear-gradient(135deg,#8E8E8E,#F1F1F1 45%,#A8A8A8)"),
        ColorGroup(
            key: "print", name: "Prints & Multi",
            css: "conic-gradient(#A8232E 0 25%,#E5C24A 0 50%,#2C4F8E 0 75%,#3F6B4A 0)"),
    ]

    /// Colors light enough to need a hairline edge on white (taxonomy.ts `LIGHT_COLORS`).
    static let lightColors: Set<String> = ["white", "beige", "yellow", "gold", "silver", "pink"]
}

/// Lowercase without accents, for accent-insensitive matching ("her" finds Hermès). The site's `fold()`
/// (app/lib/browse/text.ts).
nonisolated func fold(_ s: String) -> String {
    let marks: ClosedRange<UInt32> = 0x300...0x36F
    var out = String.UnicodeScalarView()
    for u in s.decomposedStringWithCanonicalMapping.unicodeScalars where !marks.contains(u.value) {
        out.append(u)
    }
    return String(out).lowercased()
}

/// A URL-safe name, the site's `slug()` (app/lib/browse/text.ts): "Tops & Blouses" → "tops-blouses", "Hermès" →
/// "hermes", "Women’s Watches" → "womens-watches".
nonisolated func slug(_ s: String) -> String {
    var out = ""
    var gap = false
    for u in fold(s).unicodeScalars {
        if u == "’" || u == "'" { continue }
        let v = u.value
        if (v >= 97 && v <= 122) || (v >= 48 && v <= 57) {
            if gap, !out.isEmpty { out.append("-") }
            gap = false
            out.unicodeScalars.append(u)
        } else {
            gap = true
        }
    }
    return out
}
