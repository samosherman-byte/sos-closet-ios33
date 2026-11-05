import Foundation

// Which photos go where (SPEC §10, Sam, November 1), ported from the site's app/lib/catalog/photos.ts. Each photo gets
// a role from its description: the words after " – " in its Shopify alt text, or the whole alt when there's no dash.
//   look:  the piece itself (front, back, details). On cards and first on the product page.
//   proof: what proves something: stamps, serials, hallmarks, model markings, a mill's label, the original box, dust
//          bag, cards, a catalog. A label counts only from a house buyers authenticate (LUX), and a sneaker's size tag
//          only from the brands resale buyers check (SNKR). Last on the product page, under "Labels & markings".
//   off:   generic size, fiber and care labels, anything about country of origin, hangtags ("New with tags" says it
//          instead) and model or retail images. Not shown.
// photoRole() and its lists are the site's (and the prototype's), unchanged. Nothing here touches the photos or
// Shopify: it only decides which photos show where. (The site's photo check, sortPhoto()'s doubts, is a page for Sam
// on the site and isn't ported.)

nonisolated enum PhotoRole: String, Sendable, Hashable {
    case look, proof, off
}

nonisolated enum PhotoRules {
    /// Houses whose brand or maker label counts as proof (buyers authenticate them). Lower case. (photos.ts `LUX`)
    static let lux: Set<String> = Set(
        ("Hermès|Gucci|Louis Vuitton|Chanel|Celine|Valentino|Balenciaga|Miu Miu|Dolce & Gabbana|Jimmy Choo|"
            + "Brunello Cucinelli|Ermenegildo Zegna|David Yurman|Judith Leiber|Roberta di Camerino|Akris|Akris Punto|"
            + "IPPOLITA")
            .split(separator: "|").map { $0.lowercased() })

    /// Sneaker brands whose size tag resale buyers check (photos.ts `SNKR`).
    static let snkr: Set<String> = ["adidas", "nike", "jordan", "new balance"]

    // The site's patterns, character for character.
    static let model = JSRegex(
        #"\bmodel (front|view|wearing)|\bwearing\b|\bworn\b|styling image|retail (image|detail|close-up|full-length)"#)
    static let tags = JSRegex(#"hang ?tags?|original tags?|package label"#)
    static let proof = JSRegex(
        #"heat stamp|serial|hallmark|\bmarkings?\b|\bmarked\b|model code|authentic|guarantee card|information card|brand card|\bcard\b|certificate|catalog|original box|\bbox\b|dust ?bag|pouch|with case|included accessories|signature tag|\b925\b|loro piana|mill label|brand stamp|maker stamp|signature base|signature detail"#
    )
    static let strong = JSRegex(
        #"\b(labels?|tabs?|tags?|fiber|fibre|care|composition|content|materials?)\b|\b(brand|maker) size|\bsize (and|fiber|code|table)\b"#
    )
    static let weak = JSRegex(
        #"\b(size[sd]?|origin|made in|maker|style|sku|code)\b|\bbrand\b(?!\s+(charm|patch|and trim|and hardware|plaque))"#
    )
    static let look = JSRegex(
        #"\b(front|back|rear|reverse|side|neckline|collar(?!\s+(brand|label|size))|hem|cuff|sleeve|pocket|waist|lapel|buttons?|placket|closure|zip|zipper|zips|interior(?!\s+(brand|maker))|lining|soles?|outsoles?|heels?|insoles?(?!\s+(brand|logo))|straps?|hardware|texture|detail|view|angle|angled|pair|top|base|print|embroider\w*|knit|weave|pleats?|drape|fringe|bead\w*|quilt\w*|clasp|dial|bodice|ruffle|trim|patch|plaque|charm|logo|graphics?|seam|panel|compartments?|gusset|edge|toe|vamp|bolero|gown|layers|opening|flap|ties|stitch\w*|relief|pendant|cord|chain|caseback|bracelet|lens|guitar|family|single|face|three.quarter|full-length|close-up|unzipped|shoulder|yoke|hood|cape|belt|belted|epaulets?|dedication|daylight|footbeds?|wedge|jacquard|windowpane|paisley|tweed|satin|lace|corduroy|silk|toggles|frog)\b"#
    )
    /// The words before "with", "showing", "marked", "reading", "on", "inside", "in the" or a comma.
    static let subjectEnd = JSRegex(#"\s(?:with|showing|marked|reading|on|inside|in the)\s|,\s"#)
    static let unnamed = JSRegex(#"photo \d+ of \d+$"#)
    static let withOrAnd = JSRegex(#"\b(with|and)\b"#)
    static let labelOrTag = JSRegex(#"\b(label|tag)\b"#)
    static let sizeStamp = JSRegex(#"size \d|size stamp"#)
    static let detailWords = JSRegex(#"plaque|patch|charm"#)
    static let origin = JSRegex(#"origin|made in"#)
    static let brandLabel = JSRegex(#"\b(brand|maker)\b|^label$"#)
}

/// The words before "with", "showing", "on", "inside"… ("Back of … with size S label" is a back). photos.ts `subjectOf`.
nonisolated func photoSubject(_ d: String) -> String {
    PhotoRules.subjectEnd.before(d)
}

/// A photo's description: the words after " – " in its alt text, or the whole alt when there's no dash
/// (photos.ts `photoDesc`).
nonisolated func photoDesc(_ alt: String?) -> String {
    let a = (alt ?? "") as NSString
    let i = a.range(of: " – ")
    return (i.location != NSNotFound ? a.substring(from: i.location + 3) : a as String).jsTrimmed
}

/// A photo's role from its description (`desc`), for a piece by `designer`, the photo being the piece's `index`th
/// (0 = the cover, always look). `why` is "", "unnamed", "model", "nwt" (a photo of the piece with its hangtag),
/// "tags", "label", "origin" or "size tag". photos.ts `photoRole`, line for line.
nonisolated func photoRole(_ desc: String?, designer: String, index: Int) -> (role: PhotoRole, why: String) {
    let r = PhotoRules.self
    let d = (desc ?? "").lowercased().jsTrimmed
    if index == 0 { return (.look, "") }
    if d.isEmpty || r.unnamed.test(d) { return (.look, "unnamed") }
    if r.model.test(d) { return (.off, "model") }
    let b = designer.lowercased()
    let lux = r.lux.contains(b)
    if let t = r.tags.firstMatch(d) {
        let pre = d.utf16Prefix(t.index)
        return r.withOrAnd.test(pre) && r.look.test(pre) ? (.look, "nwt") : (.off, "tags")
    }
    if let p = r.proof.firstMatch(d), !(p.text.contains("mark") && r.labelOrTag.test(d)) {
        return r.sizeStamp.test(d) && !lux ? (.off, "label") : (.proof, "")
    }
    let subj = photoSubject(d)
    var label = r.strong.test(subj) && !r.detailWords.test(subj)
    if !label {
        let w = r.weak.firstMatch(subj)
        let k = r.look.firstMatch(subj)
        if let w {
            label = (k == nil || w.index < k!.index) && !r.detailWords.test(subj)
        }
    }
    if !label { return (.look, "") }
    if r.origin.test(d) { return (.off, "origin") }
    if lux && r.brandLabel.test(subj) { return (.proof, "label") }
    if r.snkr.contains(b) && d.contains("size") { return (.proof, "size tag") }
    return (.off, "label")
}

/// A piece's photos, in Shopify's order, sorted by role (photos.ts `SortedPhotos`).
nonisolated struct SortedPhotos: Sendable {
    /// The piece itself, in Shopify's order, the cover first: cards swipe through these.
    var look: [PieceImage] = []
    /// What proves something: after the look photos on the product page, under Labels & markings.
    var proof: [PieceImage] = []
    /// Not shown.
    var off: [PieceImage] = []
    /// A hangtag or original-tags photo: the product page says "New with tags".
    var nwt = false
}

/// A piece's photos sorted by role (photos.ts `sortPhotos`), for a piece by `designer`.
nonisolated func sortPhotos(_ photos: [PieceImage], designer: String) -> SortedPhotos {
    var out = SortedPhotos()
    for (i, photo) in photos.enumerated() {
        let (role, why) = photoRole(photoDesc(photo.alt), designer: designer, index: i)
        switch role {
        case .look: out.look.append(photo)
        case .proof: out.proof.append(photo)
        case .off: out.off.append(photo)
        }
        if why == "tags" || why == "nwt" { out.nwt = true }
    }
    return out
}
