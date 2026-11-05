import Foundation

// From a product to a piece, ported line for line from the site's app/lib/catalog/record.ts.
// Tags carry the structure (SPEC §13): dept:women|men|jewelry|home, cat:<slug>, sub:<slug>, color:<key>,
// id:<prototype id>, no-designer, plus plain tags like Vintage, Signed, Fine (and featured, the piece that leads a case).
// "New with tags" (Sam, November 2) isn't a plain tag: it only sets the condition on the product page, so it never
// becomes a filter, a Show only choice or a search word. Nor is a pre-owned piece's grade, condition:like-new or
// condition:excellent (Sam, November 3): a structured tag, read only by the product page's status line.
// dept:jewelry and dept:home are both Jewelry & Objects since November 1: nothing in Shopify is retagged.

nonisolated enum RecordMaps {
    /// Each category by its slug ("clothing" → "Clothing"). record.ts `CAT_BY_SLUG`.
    static let catBySlug: [String: String] = {
        var out: [String: String] = [:]
        for d in Dept.allCases {
            for name in d.categories { out[slug(name)] = name }
        }
        return out
    }()

    /// Each type by its slug ("tops-blouses" → "Tops & Blouses"). record.ts `SUB_BY_SLUG`.
    static let subBySlug: [String: String] = Dictionary(
        Taxonomy.subs.map { (slug($0), $0) }, uniquingKeysWith: { _, last in last })

    static let colorKeys: Set<String> = Set(Taxonomy.colors.map(\.key))

    /// Categories that belong to one department only, so a missing dept: tag can be inferred. record.ts `DEPT_OF_CAT`.
    static let deptOfCat: [String: Dept] = {
        var out: [String: Dept] = [:]
        for d in Dept.allCases {
            for name in d.categories where Dept.allCases.filter({ $0.categories.contains(name) }).count == 1 {
                out[name] = d
            }
        }
        return out
    }()

    static let whitespace = JSRegex(#"\s+"#)
    static let markup = JSRegex(#"<[^>]*>"#)
    static let nbsp = JSRegex(#"&nbsp;|&#160;"#)
    static let amp = JSRegex(#"&amp;"#)
    static let apostrophe = JSRegex(#"&(rsquo|#39|#x27|apos);"#)
    static let entity = JSRegex(#"&[a-z0-9#]+;"#, ignoreCase: true)
    static let firstSentence = JSRegex(#"^[^.!?]*[.!?]"#)
}

/// A condition: tag's grade, with any capitals or spacing ("Like New" reads as like-new); nil for any other value.
nonisolated func gradeOf(_ val: String) -> Grade? {
    let key = slug(val)
    return Merch.conditionGrades.first { $0.tag == key }?.grade
}

/// What a product's tags say (record.ts `ParsedTags`).
nonisolated struct ParsedTags: Hashable, Sendable {
    var dept: Dept?
    var cat: String?
    var sub: String?
    var colors: [String] = []
    var id: String?
    var noDesigner = false
    /// The product has the tag "New with tags".
    var newWithTags = false
    /// Its grade, from a condition: tag: "Like new" or "Excellent", else nil.
    var grade: Grade?
    var plain: [String] = []
}

/// record.ts `parseTags`
nonisolated func parseTags(_ tags: [String]) -> ParsedTags {
    var out = ParsedTags()
    let grades = Grade.allCases
    for raw in tags {
        let t = raw.jsTrimmed
        let colon = (t as NSString).range(of: ":").location
        let i = colon == NSNotFound ? -1 : colon
        let key = i > 0 ? (t as NSString).substring(to: i).lowercased() : ""
        let val = i > 0 ? (t as NSString).substring(from: i + 1).jsTrimmed : ""
        if key == "dept", let d = Taxonomy.deptTag[val.lowercased()] {
            out.dept = d
        } else if key == "cat" {
            out.cat = RecordMaps.catBySlug[val] ?? out.cat
        } else if key == "sub" {
            out.sub = RecordMaps.subBySlug[val] ?? out.sub
        } else if key == "color" {
            if RecordMaps.colorKeys.contains(val) && !out.colors.contains(val) { out.colors.append(val) }
        } else if key == "id" {
            out.id = val.isEmpty ? nil : val
        } else if key == "condition" {
            // Two grades on one piece: the lower one, since understating a piece's condition never misleads a buyer.
            if let g = gradeOf(val), out.grade.map({ grades.firstIndex(of: g)! > grades.firstIndex(of: $0)! }) ?? true {
                out.grade = g
            }
        } else if t.lowercased() == "no-designer" {
            out.noDesigner = true
        } else if t.lowercased() == Merch.newWithTagsTag.lowercased() {
            out.newWithTags = true
        } else if key.isEmpty && !t.isEmpty {
            out.plain.append(t)
        }
    }
    return out
}

/// "S/M" on one piece's label means it fits as S and as M. record.ts `splitSize`.
nonisolated func splitSize(_ size: String) -> [String] {
    size.components(separatedBy: "/").map(\.jsTrimmed).filter { !$0.isEmpty }
}

/// The photo size standard for the card (SPEC §7), from the sos.photo_fit metafield: only when it was measured on the
/// cover the card shows, and only when it changes anything. A value that isn't one the tool would write is ignored.
/// record.ts `photoFit`.
nonisolated func photoFit(_ r: ProductRecord) -> PhotoFit? {
    guard let raw = r.metafields.photoFit, !raw.isEmpty, let cover = r.coverId, !cover.isEmpty,
        let v = jsonValue(raw) as? [String: Any], (v["imageId"] as? String) == cover
    else { return nil }
    let scale = jsNumber(v["scale"])
    let drop = jsNumber(v["drop"])
    guard scale > 0.2 && scale <= 1.4, drop >= 0 && drop < 50 else { return nil }
    let rawTop = v["top"].flatMap { $0 is NSNull ? nil : $0 }
    let top = rawTop.map(jsNumber).flatMap { $0 >= 0 && $0 < 100 ? $0 : nil }
    if scale == 1 && drop == 0 && top == nil { return nil }
    return PhotoFit(scale: scale, drop: drop, top: top)
}

/// Turns a product into a piece, or nil when nothing of it is for sale any more. `sold: true` keeps a sold piece (for
/// its own page, which says it has sold): its sizes are empty and its price is what it was. record.ts `toPiece`.
nonisolated func toPiece(_ r: ProductRecord, sold: Bool = false) -> Piece? {
    let available = r.variants.filter(\.available)
    let priced = !available.isEmpty ? available : sold ? r.variants : []
    guard let price = priced.map(\.price).min() else { return nil }
    let t = parseTags(r.tags)
    let fit = photoFit(r)
    // Cards swipe through the piece's own photos only (SPEC §7, §10 Which photos go where).
    let look = sortPhotos(r.images, designer: r.vendor).look
    let cat = t.cat ?? RecordMaps.catBySlug[slug(r.productType)]
    let dept = t.dept ?? cat.flatMap { RecordMaps.deptOfCat[$0] }
    var sizes: [String] = []
    for v in available {
        guard let size = v.size, !size.isEmpty else { continue }
        for z in splitSize(size) where !sizes.contains(z) { sizes.append(z) }
    }
    // The label size stays for display; behind it, the size it fits on one scale (SPEC §9, Standard sizes).
    let sized = fitOf(SizedPiece(dept: dept, cat: cat, sub: t.sub, designer: r.vendor), sizes)
    return Piece(
        id: t.id ?? r.handle,
        handle: r.handle,
        dept: dept,
        cat: cat,
        sub: t.sub,
        designer: r.vendor,
        noDesigner: t.noDesigner,
        title: r.title,
        detail: r.metafields.detailLine ?? "",
        price: price,
        sizes: sizes,
        ax: sized.ax,
        fz: sized.fz,
        fnote: sized.fnote.isEmpty ? nil : sized.fnote,
        colors: t.colors,
        tags: t.plain,
        authenticated: r.metafields.authenticated,
        image: r.images.first,
        morePhotos: look.count > 1 ? look[1..<min(20, look.count)].map { CardPhoto(url: $0.url, width: $0.width) } : nil,
        fit: fit,
        story: nil
    )
}

/// A piece's line of story in a small department's case (SPEC §7): its Story line (the sos.story metafield); without
/// one, the first sentence of its description when that's at most `Merch.storyFallbackMax` characters; else none ("").
/// record.ts `storyOf`.
nonisolated func storyOf(_ r: ProductRecord) -> String {
    let m = RecordMaps.self
    if let own = r.metafields.story.map({ m.whitespace.replaceAll($0, with: " ").jsTrimmed }), !own.isEmpty {
        return own
    }
    var text = r.summary ?? m.markup.replaceAll(r.descriptionHtml, with: " ")
    text = m.nbsp.replaceAll(text, with: " ")
    text = m.amp.replaceAll(text, with: "&")
    text = m.apostrophe.replaceAll(text, with: "’")
    text = m.entity.replaceAll(text, with: " ")
    text = m.whitespace.replaceAll(text, with: " ").jsTrimmed
    // (The prototype's rule: up to the first full stop, question or exclamation mark.)
    let first = m.firstSentence.firstMatch(text)?.text ?? ""
    return first.jsLength <= Merch.storyFallbackMax ? first : ""
}

/// New with tags (SPEC §10): the product has the tag "New with tags" (Sam, November 2), or, as a backup, one of its
/// photos is a hangtag or original-tags shot (`hangtag`, from sortPhotos; November 1). Every other piece is pre-owned.
/// record.ts `isNewWithTags`.
nonisolated func isNewWithTags(_ tags: [String], hangtag: Bool) -> Bool {
    hangtag || parseTags(tags).newWithTags
}

/// Everything the product page shows; a sold piece too (its page says so, with similar pieces). record.ts
/// `toProductDetail`.
nonisolated func toProductDetail(_ r: ProductRecord) -> ProductDetail? {
    guard let piece = toPiece(r, sold: true) else { return nil }
    // The piece's own photos first, then what proves something; generic labels, origin, hangtag and model photos
    // aren't shown, and a hangtag photo says "New with tags" instead (SPEC §10, Which photos go where), as the tag does.
    let sorted = sortPhotos(r.images, designer: r.vendor)
    let newWithTags = isNewWithTags(r.tags, hangtag: sorted.nwt)
    return ProductDetail(
        piece: piece,
        productId: r.productId ?? r.handle,
        descriptionHtml: r.descriptionHtml,
        photos: sorted.look,
        proof: sorted.proof,
        newWithTags: newWithTags,
        // A grade only for a pre-owned piece: New with tags never shows one, even beside a stray condition: tag.
        grade: newWithTags ? nil : parseTags(r.tags).grade,
        variants: r.variants,
        colorName: r.metafields.colorName ?? "",
        swatch: r.metafields.swatch ?? "",
        details: r.metafields.details,
        seoTitle: (r.seoTitle ?? "").isEmpty ? "\(piece.noDesigner ? "" : piece.designer + " ")\(piece.title)" : r.seoTitle!,
        seoDescription: r.seoDescription ?? ""
    )
}

/// Pieces that can't be placed in a department section, for a catalog health check. record.ts `structureProblems`.
nonisolated func structureProblems(_ r: ProductRecord) -> [String] {
    let t = parseTags(r.tags)
    var problems: [String] = []
    if t.dept == nil { problems.append("no dept: tag") }
    if t.cat == nil { problems.append("no cat: tag") }
    if t.sub == nil { problems.append("no sub: tag") }
    if t.colors.isEmpty { problems.append("no color: tag") }
    if (r.metafields.detailLine ?? "").isEmpty { problems.append("no detail line") }
    if r.images.isEmpty { problems.append("no photo") }
    return problems
}
