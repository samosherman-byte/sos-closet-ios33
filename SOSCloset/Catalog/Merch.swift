import Foundation

// Merchandising, ported from the site's app/settings/merch.ts: which cutout tile stands for each category, the
// hold-back fallback, the case, the condition grades, the home page (its turntable, its rooms and the size standard
// their photos are placed by) and the contact details. Pieces are named by their prototype id (the Shopify tag
// id:<id>). The rooms' pieces aren't here: Sam picks them in Shopify, a "Home row" collection each (SPEC §11a).

/// A pre-owned piece's grade (merch.ts `Grade`, `CONDITION_GRADES`; Sam, November 3; SPEC §10), best first. Only
/// these two: a piece with neither says Pre-owned alone, and a New with tags piece shows none.
nonisolated enum Grade: String, CaseIterable, Sendable, Hashable {
    case likeNew = "Like new"
    case excellent = "Excellent"
}

/// The kinds of piece in the home page's rooms (merch.ts `HomeKind`): clothing (dresses too) and shoes. The raw values
/// are the keys of `home` in the sos.photo_fit metafield.
nonisolated enum HomeKind: String, CaseIterable, Sendable, Hashable {
    case garment, shoes
}

nonisolated enum Merch {
    // MARK: Tiles (SPEC §7)

    /// The cutout tiles (merch.ts `TILES`): photo cutouts of real pieces, in the app's SiteAssets/tiles/ as
    /// `<tile>.webp`, copied unchanged from the site's public/tiles/.
    static let tiles: [String] = [
        "women-handbags",
        "women-clothing",
        "women-shoes",
        "women-accessories",
        "men-clothing",
        "men-shoes",
        "men-accessories",
        "jewelry-jewelry",
        "jewelry-watches",
        "home-art",
        "home-home",
    ]

    /// The tile for each category, in the tile row and the directory (merch.ts `CAT_TILE`). Jewelry & Objects shows its
    /// tiles once it's a full department: a case has no tile row (SPEC §7).
    static let catTile: [Dept: [String: String]] = [
        .women: [
            "Handbags": "women-handbags",
            "Clothing": "women-clothing",
            "Shoes": "women-shoes",
            "Accessories": "women-accessories",
        ],
        .men: [
            "Clothing": "men-clothing",
            "Shoes": "men-shoes",
            "Accessories": "men-accessories",
        ],
        .jewelry: [
            "Jewelry": "jewelry-jewelry",
            "Watches": "jewelry-watches",
            "Art": "home-art",
            "Home": "home-home",
        ],
    ]

    /// The department row on New Arrivals, Vintage and designer pages: each department borrows one of its tiles
    /// (merch.ts `CAT_TILE.s`).
    static let deptTile: [Dept: String] = [
        .women: "women-handbags",
        .men: "men-clothing",
        .jewelry: "jewelry-watches",
    ]

    /// A tile's cutout in the app (SiteAssets/tiles/<tile>.webp; the site's `tileSrc`). Nil when SiteAssets/ is missing.
    static func tileURL(_ tile: String) -> URL? {
        siteAssetURL("/tiles/\(tile).webp")
    }

    /// One of the site's public/ files that ship in the app (SiteAssets/), by its path on the site ("/home/cut-jackie.webp").
    static func siteAssetURL(_ sitePath: String) -> URL? {
        guard let root = StoreConfig.siteAssetsURL else { return nil }
        return root.appending(path: String(sitePath.drop { $0 == "/" }))
    }

    // MARK: The order and the case (SPEC §7)

    /// Pieces kept out of the front row without changing their date: each moves to just after the piece named
    /// (merch.ts `HOLD_BACK`). In the real store this is the product metafield custom.place_after; this list is the
    /// fallback until any piece has one. [id, after], in order.
    static let holdBack: [(id: String, after: String)] = [("c179", "c45")]

    /// A department with fewer than this many pieces is a case (merch.ts `CASE_MAX`; Sam, November 1; SPEC §7): no tile
    /// row, no headings and no Filter button; its pieces two across, each with its story line.
    static let caseMax = 12

    /// The product tag that puts a piece first in a case (merch.ts `FEATURED_TAG`).
    static let featuredTag = "featured"

    /// The product tag that says a piece still has its original tags (merch.ts `NEW_WITH_TAGS_TAG`; Sam, November 2;
    /// SPEC §10). Read with any capitals; it's never a filter, a chip or a word on a card.
    static let newWithTagsTag = "New with tags"

    /// The condition: tag values and their grades, best first (merch.ts `CONDITION_GRADES`).
    static let conditionGrades: [(tag: String, grade: Grade)] = [("like-new", .likeNew), ("excellent", .excellent)]

    /// A piece's story line in a case is its description's first sentence only when it's at most this long
    /// (merch.ts `STORY_FALLBACK_MAX`).
    static let storyFallbackMax = 140

    // MARK: The home page's turntable (SPEC §11a)

    /// A bag on the turntable (merch.ts `TurntableBag`). `cut`: its cutout (SiteAssets/home/), cut from the bag's own
    /// photo in a 4:5 frame, the bag 90% of its width. `cm`: how wide the bag is, for true sizes to each other.
    /// `top`/`bot`: where the bag starts and ends in its frame (shares of the height), so every bag stands on the same
    /// floor.
    nonisolated struct TurntableBag: Hashable, Sendable {
        var id: String
        /// The site's path to the cutout ("/home/cut-jackie.webp"); `cutURL` finds it in the app.
        var cut: String
        var cm: Double
        var top: Double
        var bot: Double
        /// The bag's name in its credit (the designer comes from the piece).
        var name: String
        /// Until a piece with this id is in the shop: who made it, what it is, what the credit says, where it leads.
        var soon: Soon?

        nonisolated struct Soon: Hashable, Sendable {
            var designer: String
            var title: String
            var note: String
            /// The site's link ("/women#handbags": Women at Handbags).
            var href: String
            var alt: String
        }

        var cutURL: URL? { Merch.siteAssetURL(cut) }
    }

    /// The table's shape (merch.ts `TurntableShape`), as shares of the stage's width (fw, rx) and height (floor, lift);
    /// shrink and wash at the back.
    nonisolated struct TurntableShape: Hashable, Sendable {
        /// A 34 cm bag's frame width, in front.
        var fw: Double
        /// How far the side bags stand from the middle.
        var rx: Double
        /// Where the bag in front stands.
        var floor: Double
        /// How much higher the very back stands.
        var lift: Double
        /// How much smaller a bag is at the very back.
        var shrink: Double
        /// How far toward the white it's washed at the very back.
        var wash: Double
    }

    nonisolated struct Turntable: Hashable, Sendable {
        /// The bag in front to begin with.
        var front: Int
        var bags: [TurntableBag]
        var wide: TurntableShape
        /// A stage under 560pt wide (phones).
        var narrow: TurntableShape
    }

    /// merch.ts `TURNTABLE`: left to right as Sam named them (October 30), the Jackie in front to begin with.
    static let turntable = Turntable(
        front: 1,
        bags: [
            TurntableBag(
                id: "lv-brea", cut: "/home/cut-lv-brea.webp", cm: 33, top: 0.128, bot: 0.871, name: "Bréa",
                soon: .init(
                    designer: "Louis Vuitton", title: "Bréa", note: "New arrival", href: "/women#handbags",
                    alt: "Louis Vuitton Bréa handbag in red Epi leather with silver-tone hardware")),
            TurntableBag(id: "jackie", cut: "/home/cut-jackie.webp", cm: 34, top: 0.074, bot: 0.927, name: "Jackie 1961"),
            TurntableBag(id: "bamboo", cut: "/home/cut-bamboo.webp", cm: 29, top: 0.1, bot: 0.9, name: "Bamboo"),
        ],
        wide: TurntableShape(fw: 0.5, rx: 0.395, floor: 0.965, lift: 0.13, shrink: 0.42, wash: 0.2),
        narrow: TurntableShape(fw: 0.56, rx: 0.36, floor: 0.965, lift: 0.12, shrink: 0.44, wash: 0.2)
    )

    // MARK: The home page's rooms (SPEC §11a)

    /// The home size standard (merch.ts `HOME_STANDARD`; Sam, October 30, SPEC §11a): one square tile for every room.
    /// tools/home_fit.py measures each cover by these numbers and stores its place with `version`; a place measured to
    /// an older version isn't used. Until a cover is measured, its photo is `fallback` of the tile's width, centred, its
    /// bottom on the `foot` line. On phones a piece of clothing grows inside its tile by its own g, at most `grow`.
    nonisolated struct HomeStandard: Hashable, Sendable {
        var version: Int
        var area: Double
        var fill: Double
        var foot: Double
        var fallback: Double
        var grow: Double
    }

    /// merch.ts `HOME_STANDARD` (version 4: November 1, clothing about 25% bigger).
    static let homeStandard = HomeStandard(version: 4, area: 0.44, fill: 0.75, foot: 0.965, fallback: 0.8, grow: 1.1)

    /// Each kind's size limits in its tile (merch.ts `HOME_KINDS`).
    nonisolated struct HomeKindLimits: Hashable, Sendable {
        var area: Double
        var width: Double
        var height: Double
    }

    /// merch.ts `HOME_KINDS`
    static let homeKinds: [HomeKind: HomeKindLimits] = [
        .garment: HomeKindLimits(area: 1.54, width: 0.8, height: 0.92),
        .shoes: HomeKindLimits(area: 1.1, width: 0.88, height: 0.92),
    ]

    /// A room on the home page (merch.ts `HomeRoom`).
    nonisolated struct HomeRoom: Hashable, Sendable {
        var name: String
        /// The department and category it shows: its View all tile counts the category's pieces.
        var dept: Dept
        var cat: String
        /// The site's link for its title and View all ("/women#clothing": the department at that category).
        var href: String
        var kind: HomeKind
        /// The Shopify collection that holds the room's pieces ("Home row · …" in the admin, manual sort).
        var collection: String
        /// How many the room shows: the first this many of its collection's pieces that are for sale.
        var show: Int
    }

    /// merch.ts `HOME_ROOMS` (Sam, October 30): clothing first, Men's right under Women's, then the shoes the same way.
    static let homeRooms: [HomeRoom] = [
        HomeRoom(
            name: "Women’s clothing", dept: .women, cat: "Clothing", href: "/women#clothing", kind: .garment,
            collection: "home-row-womens-clothing", show: 8),
        HomeRoom(
            name: "Men’s clothing", dept: .men, cat: "Clothing", href: "/men#clothing", kind: .garment,
            collection: "home-row-mens-clothing", show: 8),
        HomeRoom(
            name: "Women’s shoes", dept: .women, cat: "Shoes", href: "/women#shoes", kind: .shoes,
            collection: "home-row-womens-shoes", show: 8),
        HomeRoom(
            name: "Men’s shoes", dept: .men, cat: "Shoes", href: "/men#shoes", kind: .shoes,
            collection: "home-row-mens-shoes", show: 8),
    ]

    /// A room piece that shows another of its own Shopify photos than its cover (merch.ts `HOME_PHOTO`; Sam, October
    /// 30): `filePattern` picks the photo by its file name (a regular expression, any capitals); until the piece has such
    /// a photo, its cover shows. `fit` was measured by hand with tools/home_fit.py.
    nonisolated struct HomePhoto: Hashable, Sendable {
        var filePattern: String
        var alt: String
        var fit: HomeFit

        /// Whether a photo's address is this one (the site's `alt.file.test(url)`).
        func matches(_ url: URL) -> Bool {
            JSRegex(filePattern, ignoreCase: true).test(url.absoluteString)
        }
    }

    /// merch.ts `HOME_PHOTO`, by piece id: the Coppley as its jacket alone.
    static let homePhoto: [String: HomePhoto] = [
        "coppley": HomePhoto(
            filePattern: "-jacket[._]", alt: "Coppley light beige windowpane suit jacket",
            fit: HomeFit(width: 93.59, left: 2.79, top: -5.72, grow: 1.093))
    ]

    // MARK: Contact

    /// merch.ts `CONTACT`
    nonisolated struct Contact: Hashable, Sendable {
        var email: String
        var instagram: URL
        var instagramHandle: String
    }

    static let contact = Contact(
        email: "soscloset33@gmail.com",
        instagram: URL(string: "https://www.instagram.com/soscloset33/")!,
        instagramHandle: "@SOSCLOSET33"
    )
}
