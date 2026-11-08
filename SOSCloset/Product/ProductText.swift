import Foundation

// What the product page says besides its status (SPEC §10), from the site's app/components/product/ProductPage.tsx:
// "You may also like", what Details lists, and the description as the page reads it.

/// "You may also like": six pieces from the same category, topped up from the same department (ProductPage.tsx
/// `alsoLike`). Six fills its rows at two across.
nonisolated func alsoLike(_ p: Piece, _ pieces: [Piece]) -> [Piece] {
    var also = pieces.filter { $0.id != p.id && $0.dept == p.dept && $0.cat == p.cat }
    if also.count < 6 {
        let had = Set(also.map(\.id))
        also += pieces.filter { $0.id != p.id && $0.dept == p.dept && !had.contains($0.id) }
    }
    return Array(also.prefix(6))
}

/// Details keeps only what the page doesn't already say (the written facts some pieces have), and the authentication
/// card of an authenticated piece; with nothing left, the page shows no Details (SPEC §10, "Details says only what's
/// new").
nonisolated func detailsList(_ p: ProductDetail) -> [String] {
    var list = p.details
    if p.authenticated && !list.contains(where: { $0.range(of: "authentic", options: .caseInsensitive) != nil }) {
        list.append("Professionally authenticated, with authentication card")
    }
    return list
}

// MARK: - The description

/// One block of a description as Shopify's HTML has it: a paragraph (its line breaks kept), or an item of a list.
nonisolated enum DescriptionBlock: Hashable, Sendable {
    case paragraph(String)
    case item(String)

    var text: String {
        switch self {
        case .paragraph(let t), .item(let t): t
        }
    }
}

/// The description's blocks, from Shopify's HTML (the site shows the HTML itself): paragraphs and list items, their
/// text with the markup taken out and the entities read, line breaks (`<br>`) kept inside a paragraph. Empty blocks
/// are left out.
nonisolated func descriptionBlocks(_ html: String) -> [DescriptionBlock] {
    // (A private-use character, which isn't white space, stands for each line break until the spaces are tidied.)
    let breakMark: Character = "\u{E000}"
    var blocks: [DescriptionBlock] = []
    var text = ""
    var inItem = false

    func flush() {
        var t = DescriptionText.space.replaceAll(text, with: " ")
        t = decodeEntities(t)
        t = t.split(separator: breakMark, omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        text = ""
        guard !t.isEmpty else { return }
        blocks.append(inItem ? .item(t) : .paragraph(t))
    }

    let ns = html as NSString
    var at = 0
    for tag in DescriptionText.tag.matches(html) {
        text += ns.substring(with: NSRange(location: at, length: tag.range.location - at))
        at = tag.range.location + tag.range.length
        let name = tag.name.lowercased()
        if name == "br" {
            text.append(breakMark)
        } else if DescriptionText.blockTags.contains(name) {
            flush()
            if name == "li" { inItem = !tag.closing }
        }
    }
    text += ns.substring(from: at)
    flush()
    return blocks
}

/// The description while it's closed (SPEC §10): the paragraphs and line breaks run on as one flow, a space apart, so
/// the three-line cut and its ellipsis work across them.
nonisolated func descriptionFlow(_ blocks: [DescriptionBlock]) -> String {
    blocks.map { $0.text.replacingOccurrences(of: "\n", with: " ") }.joined(separator: " ")
}

/// A description's HTML entities in plain text: the named ones Shopify's editor writes, and any by number.
nonisolated func decodeEntities(_ s: String) -> String {
    guard s.contains("&") else { return s }
    var out = ""
    var rest = Substring(s)
    while let amp = rest.firstIndex(of: "&") {
        out += rest[..<amp]
        let after = rest[amp...]
        if let semi = after.prefix(12).firstIndex(of: ";") {
            let name = String(after[after.index(after: amp)..<semi])
            if let ch = entity(name) {
                out += ch
                rest = after[after.index(after: semi)...]
                continue
            }
        }
        out += "&"
        rest = after.dropFirst()
    }
    return out + rest
}

private nonisolated func entity(_ name: String) -> String? {
    if name.hasPrefix("#") {
        let digits = name.dropFirst()
        let code = digits.first == "x" || digits.first == "X" ? UInt32(digits.dropFirst(), radix: 16) : UInt32(digits)
        guard let code, let scalar = Unicode.Scalar(code) else { return nil }
        // (A non-breaking space reads as a space.)
        return code == 160 ? " " : String(Character(scalar))
    }
    return DescriptionText.named[name]
}

private nonisolated enum DescriptionText {
    struct Tag {
        var range: NSRange
        var closing: Bool
        var name: String
    }

    static let space = JSRegex(#"\s+"#)
    /// The tags that start or end a block (a paragraph or a list item).
    static let blockTags: Set<String> = [
        "p", "div", "li", "ul", "ol", "h1", "h2", "h3", "h4", "h5", "h6", "blockquote", "section", "article", "tr",
        "table",
    ]
    static let named: [String: String] = [
        "amp": "&", "lt": "<", "gt": ">", "quot": "\"", "apos": "'", "nbsp": " ",
        "rsquo": "’", "lsquo": "‘", "rdquo": "”", "ldquo": "“", "hellip": "…", "mdash": "—", "ndash": "–",
        "middot": "·", "bull": "•", "deg": "°", "frac12": "½", "frac14": "¼", "frac34": "¾", "times": "×",
        "eacute": "é", "egrave": "è", "ecirc": "ê", "euml": "ë", "aacute": "á", "agrave": "à", "acirc": "â",
        "auml": "ä", "aring": "å", "ccedil": "ç", "iacute": "í", "icirc": "î", "iuml": "ï", "ntilde": "ñ",
        "oacute": "ó", "ocirc": "ô", "ouml": "ö", "oslash": "ø", "uacute": "ú", "ucirc": "û", "uuml": "ü",
        "Eacute": "É", "Egrave": "È", "Aacute": "Á", "Agrave": "À", "Ccedil": "Ç", "Ntilde": "Ñ", "Oacute": "Ó",
        "Ouml": "Ö", "Uuml": "Ü", "szlig": "ß", "reg": "®", "trade": "™", "copy": "©", "prime": "′", "Prime": "″",
    ]

    static let tag = TagFinder()

    /// Every tag in the HTML, in order. (NSRegularExpression is immutable and safe to share between threads.)
    struct TagFinder: @unchecked Sendable {
        private let regex = try! NSRegularExpression(pattern: #"<\s*(/?)\s*([a-zA-Z][a-zA-Z0-9]*)[^>]*>"#)

        func matches(_ s: String) -> [Tag] {
            let ns = s as NSString
            return regex.matches(in: s, range: NSRange(location: 0, length: ns.length)).map { m in
                Tag(range: m.range, closing: m.range(at: 1).length > 0, name: ns.substring(with: m.range(at: 2)))
            }
        }
    }
}
