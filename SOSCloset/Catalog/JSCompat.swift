import Foundation

// Small pieces of JavaScript's behavior that the site's catalog code relies on, so the Swift port gives the same
// answers line for line: its regular expressions, parseFloat() and Number(), how it writes a number as text, and a
// sort that keeps ties in order (JavaScript's sort is stable).

/// A regular expression used the way the site uses one (ICU through NSRegularExpression, which reads the site's
/// patterns as they are: lookaheads, `\b`, classes). Positions are in UTF-16 units, as in JavaScript.
/// (One difference that doesn't come up in the site's patterns: ICU counts accented letters as word characters for
/// `\b`, JavaScript only a–z, 0–9 and _.) NSRegularExpression is immutable and safe to share between threads.
nonisolated struct JSRegex: @unchecked Sendable {
    private let regex: NSRegularExpression

    init(_ pattern: String, ignoreCase: Bool = false) {
        // (A pattern that doesn't compile is a mistake in this file, caught by the tests on first use.)
        regex = try! NSRegularExpression(pattern: pattern, options: ignoreCase ? [.caseInsensitive] : [])
    }

    private func whole(_ s: String) -> NSRange { NSRange(location: 0, length: (s as NSString).length) }

    /// `re.test(s)`
    func test(_ s: String) -> Bool {
        regex.firstMatch(in: s, range: whole(s)) != nil
    }

    /// `s.match(re)` (no g flag): the first match's text, and where it starts in UTF-16 units (`.index`).
    func firstMatch(_ s: String) -> (text: String, index: Int)? {
        guard let m = regex.firstMatch(in: s, range: whole(s)) else { return nil }
        return ((s as NSString).substring(with: m.range), m.range.location)
    }

    /// `s.match(re)` (no g flag) as JavaScript's array: the whole match, then each group (nil when a group took no
    /// part); nil when there's no match.
    func groups(_ s: String) -> [String?]? {
        guard let m = regex.firstMatch(in: s, range: whole(s)) else { return nil }
        let ns = s as NSString
        return (0..<m.numberOfRanges).map { i in
            let r = m.range(at: i)
            return r.location == NSNotFound ? nil : ns.substring(with: r)
        }
    }

    /// `s.replace(re, text)` with the g flag (the text is put in as it is, with no $1 or \ escapes).
    func replaceAll(_ s: String, with text: String) -> String {
        regex.stringByReplacingMatches(
            in: s, range: whole(s), withTemplate: NSRegularExpression.escapedTemplate(for: text))
    }

    /// `s.split(re)[0]`: the text before the first match (all of it when there's none).
    func before(_ s: String) -> String {
        guard let m = regex.firstMatch(in: s, range: whole(s)) else { return s }
        return (s as NSString).substring(to: m.range.location)
    }
}

nonisolated extension String {
    /// JavaScript's `trim()`.
    var jsTrimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }

    /// JavaScript's `s.slice(0, n)`, counted in UTF-16 units.
    func utf16Prefix(_ n: Int) -> String { (self as NSString).substring(to: Swift.min(n, (self as NSString).length)) }

    /// JavaScript's `s.length`.
    var jsLength: Int { utf16.count }
}

/// JavaScript's `parseFloat(s)`: the number at the start of the text ("40R" → 40, "10.5" → 10.5), NaN when there's none.
nonisolated func jsParseFloat(_ s: String) -> Double {
    let c = Array(s.unicodeScalars.drop { CharacterSet.whitespacesAndNewlines.contains($0) })
    var i = 0
    var sign = ""
    if i < c.count, c[i] == "+" || c[i] == "-" {
        sign = String(c[i])
        i += 1
    }
    if String(String.UnicodeScalarView(c[i...])).hasPrefix("Infinity") { return sign == "-" ? -.infinity : .infinity }
    let isDigit = { (u: Unicode.Scalar) in u.value >= 48 && u.value <= 57 }
    var whole = ""
    while i < c.count, isDigit(c[i]) {
        whole.unicodeScalars.append(c[i])
        i += 1
    }
    var fraction = ""
    if i < c.count, c[i] == "." {
        var j = i + 1
        while j < c.count, isDigit(c[j]) {
            fraction.unicodeScalars.append(c[j])
            j += 1
        }
        if !whole.isEmpty || !fraction.isEmpty { i = j }
    }
    guard !whole.isEmpty || !fraction.isEmpty else { return .nan }
    var exponent = ""
    if i < c.count, c[i] == "e" || c[i] == "E" {
        var j = i + 1
        var e = "e"
        if j < c.count, c[j] == "+" || c[j] == "-" {
            e.unicodeScalars.append(c[j])
            j += 1
        }
        var digits = 0
        while j < c.count, isDigit(c[j]) {
            e.unicodeScalars.append(c[j])
            j += 1
            digits += 1
        }
        if digits > 0 { exponent = e }
    }
    let text = sign + (whole.isEmpty ? "0" : whole) + (fraction.isEmpty ? "" : "." + fraction) + exponent
    return Double(text) ?? .nan
}

private nonisolated enum JSPatterns {
    static let decimal = JSRegex(#"^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$"#)
}

/// JavaScript's `Number(v)` for a value read from JSON (or `+text` for text): a number as it is, true 1, false and
/// null 0, text that is all one number that number ("" 0), anything else NaN.
nonisolated func jsNumber(_ v: Any?) -> Double {
    switch v {
    case nil: return .nan
    case is NSNull: return 0
    case let n as NSNumber: return n.doubleValue
    case let s as String:
        let t = s.jsTrimmed
        if t.isEmpty { return 0 }
        if t == "Infinity" || t == "+Infinity" { return .infinity }
        if t == "-Infinity" { return -.infinity }
        return JSPatterns.decimal.test(t) ? (Double(t) ?? .nan) : .nan
    default: return .nan
    }
}

/// How JavaScript writes a number as text (`String(n)`, `'US ' + n`): 7 → "7", 7.5 → "7.5", -2 → "-2".
nonisolated func jsNumberText(_ n: Double) -> String {
    if n.isNaN { return "NaN" }
    if n.isInfinite { return n < 0 ? "-Infinity" : "Infinity" }
    if n == n.rounded(), abs(n) < 1e15 { return String(Int64(n)) }
    return String(n)
}

/// JavaScript's `Math.round(n)`: halves go up (2.5 → 3, -2.5 → -2).
nonisolated func jsRound(_ n: Double) -> Double { (n + 0.5).rounded(.down) }

nonisolated extension Array {
    /// A sort that keeps equal elements in the order they came (JavaScript's sort does).
    func stableSorted(by inOrder: (Element, Element) -> Bool) -> [Element] {
        enumerated()
            .sorted { a, b in
                if inOrder(a.element, b.element) { return true }
                if inOrder(b.element, a.element) { return false }
                return a.offset < b.offset
            }
            .map(\.element)
    }
}

/// Reads JSON the way `JSON.parse` does, any value at the top (nil when it isn't JSON).
nonisolated func jsonValue(_ text: String) -> Any? {
    guard let data = text.data(using: .utf8) else { return nil }
    return try? JSONSerialization.jsonObject(with: data, options: [.fragmentsAllowed])
}
