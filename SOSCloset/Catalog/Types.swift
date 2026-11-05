import Foundation

// The catalog's types, ported from the site's app/lib/catalog/types.ts with the same names and fields.

/// A photo (types.ts `PieceImage`). The sample store's are file addresses in the app's SampleStore/prototype/img/;
/// Shopify's are https addresses on its image service (`sizedImageURL` asks it for a width).
nonisolated struct PieceImage: Hashable, Sendable {
    var url: URL
    var alt: String
    var width: Int?
    var height: Int?
}

/// A photo as a card needs it: its address and how wide it is (types.ts `CardPhoto`).
nonisolated struct CardPhoto: Hashable, Sendable {
    var url: URL
    var width: Int?
}

/// The photo size standard (types.ts `PhotoFit`; SPEC §7): how much the card scales its photo, how far it drops it
/// (% of the photo's height) onto the shared baseline, and where the piece's top then sits (% of the tile's height;
/// measured since October 22, so older values lack it).
nonisolated struct PhotoFit: Hashable, Sendable {
    var scale: Double
    var drop: Double
    var top: Double?
}

/// One size of a piece in Shopify (types.ts `Variant`).
nonisolated struct Variant: Hashable, Sendable {
    var id: String
    var size: String?
    var available: Bool
    var price: Double
}

/// One piece as browse pages, menus, search and Saved see it (types.ts `Piece`; SPEC §13).
nonisolated struct Piece: Identifiable, Hashable, Sendable {
    /// The prototype id (Shopify tag id:<id>), or the handle for pieces listed later.
    var id: String
    var handle: String
    /// Nil when the product is missing its structure tags: it stays out of department sections.
    var dept: Dept?
    /// Category name, e.g. "Handbags".
    var cat: String?
    /// Type name, e.g. "Totes".
    var sub: String?
    var designer: String
    /// The vendor is a description ("Vintage"), not a designer: left out of designer lists.
    var noDesigner: Bool
    var title: String
    /// The short line under a card, e.g. "Navy & red · Size 2".
    var detail: String
    var price: Double
    /// Sizes still in stock, as their labels say them ("FR 38", "W27", "40R"). A one-piece "S/M" counts as S and M.
    var sizes: [String]
    /// Its size scale (SPEC §9, Standard sizes): nil for pieces without one (handbags, jewelry, art).
    var ax: Axis?
    /// The standard sizes it fits on that scale ("S", "7", "40R"): what the Size row, My sizes and search use.
    var fz: [String]
    /// The US size its label converts to, for the product page ("US 6"); only for a piece in one size.
    var fnote: String?
    /// Color groups (black, white, gray…), see `Taxonomy.colors`.
    var colors: [String]
    /// Plain tags such as Vintage, Signed, Fine (and featured, the piece that leads a case).
    var tags: [String]
    /// Professionally authenticated (the custom.authenticated metafield).
    var authenticated: Bool
    /// The cover: the product's first photo.
    var image: PieceImage?
    /// The piece's other photos of itself (its look photos, SPEC §10 Which photos go where), after the cover in
    /// Shopify's order, for its card to swipe through (SPEC §7). Nil when the cover is its only photo of the piece.
    var morePhotos: [CardPhoto]?
    /// The photo size standard, only when it was measured on the cover the card shows.
    var fit: PhotoFit?
    /// One line of its story, under its name in a small department's case (SPEC §7). Only on pieces in a case, and
    /// nil when there's no line.
    var story: String?
}

/// Everything the product page shows (types.ts `ProductDetail`, which extends `Piece`: the piece's own fields read
/// straight through, `detail.designer`).
@dynamicMemberLookup
nonisolated struct ProductDetail: Hashable, Sendable {
    var piece: Piece
    /// Shopify's product id (for analytics).
    var productId: String
    var descriptionHtml: String
    /// The piece's own photos (look), cover first, in Shopify's order.
    var photos: [PieceImage]
    /// What proves something (stamps, serials, hallmarks, boxes…): after the photos, under Labels & markings.
    var proof: [PieceImage]
    /// The tag "New with tags", or a hangtag or original-tags photo (not shown): the status line says "New with tags";
    /// otherwise "Pre-owned" (SPEC §10).
    var newWithTags: Bool
    /// A pre-owned piece's grade, from its condition: tag (SPEC §10): nil without one, and always for New with tags.
    var grade: Grade?
    var variants: [Variant]
    var colorName: String
    var swatch: String
    var details: [String]
    var seoTitle: String
    var seoDescription: String

    subscript<T>(dynamicMember key: KeyPath<Piece, T>) -> T { piece[keyPath: key] }
}

/// A product as either source delivers it (the Storefront API or the sample store's import files), before it's
/// turned into a Piece (types.ts `ProductRecord`). Both go through the same mapper, so the sample store checks the
/// import file too.
nonisolated struct ProductRecord: Hashable, Sendable {
    /// Shopify's product id.
    var productId: String?
    var handle: String
    var title: String
    var vendor: String
    var productType: String
    var tags: [String]
    /// ISO 8601, as Shopify sends it; compared as text, as the site does.
    var createdAt: String
    var descriptionHtml: String
    /// The start of the description as plain text (the catalog's, which leaves the description out): for a story line.
    var summary: String?
    var images: [PieceImage]
    /// The cover's media id (the sample store: its file name), to check a photo fit was measured on it.
    var coverId: String?
    var variants: [Variant]
    var metafields: Metafields
    var seoTitle: String?
    var seoDescription: String?

    nonisolated struct Metafields: Hashable, Sendable {
        var detailLine: String?
        var authenticated: Bool = false
        var colorName: String?
        var swatch: String?
        var details: [String] = []
        /// Handle of the piece this one is held back behind (custom.place_after).
        var placeAfter: String?
        /// The sos.photo_fit metafield as it's stored: {"scale", "drop", "top", "home", "homeVersion", "imageId"}.
        var photoFit: String?
        /// The product's Story line (the sos.story metafield): its line in a case (SPEC §7).
        var story: String?
    }

    init(
        productId: String? = nil, handle: String, title: String, vendor: String, productType: String, tags: [String],
        createdAt: String, descriptionHtml: String = "", summary: String? = nil, images: [PieceImage] = [],
        coverId: String? = nil, variants: [Variant] = [], metafields: Metafields = Metafields(),
        seoTitle: String? = nil, seoDescription: String? = nil
    ) {
        self.productId = productId
        self.handle = handle
        self.title = title
        self.vendor = vendor
        self.productType = productType
        self.tags = tags
        self.createdAt = createdAt
        self.descriptionHtml = descriptionHtml
        self.summary = summary
        self.images = images
        self.coverId = coverId
        self.variants = variants
        self.metafields = metafields
        self.seoTitle = seoTitle
        self.seoDescription = seoDescription
    }
}
