import Foundation

/// Parses CSV text (RFC 4180: quoted fields, doubled quotes, line breaks inside quotes) into rows keyed by the header
/// row. The site's app/lib/catalog/csv.ts `parseCsv`, line for line.
nonisolated func parseCsv(_ text: String) -> [[String: String]] {
    var rows: [[String]] = []
    var row: [String] = []
    var field = String.UnicodeScalarView()
    var quoted = false
    let c = Array(text.unicodeScalars)
    var i = 0
    while i < c.count {
        let ch = c[i]
        if quoted {
            if ch == "\"" {
                if i + 1 < c.count, c[i + 1] == "\"" {
                    field.append("\"")
                    i += 1
                } else {
                    quoted = false
                }
            } else {
                field.append(ch)
            }
        } else if ch == "\"" {
            quoted = true
        } else if ch == "," {
            row.append(String(field))
            field = String.UnicodeScalarView()
        } else if ch == "\n" || ch == "\r" {
            if ch == "\r", i + 1 < c.count, c[i + 1] == "\n" { i += 1 }
            row.append(String(field))
            rows.append(row)
            row = []
            field = String.UnicodeScalarView()
        } else {
            field.append(ch)
        }
        i += 1
    }
    if !field.isEmpty || !row.isEmpty {
        row.append(String(field))
        rows.append(row)
    }
    let kept = rows.filter { $0.count > 1 || !($0.first ?? "").isEmpty }
    guard let head = kept.first else { return [] }
    return kept.dropFirst().map { r in
        var out: [String: String] = [:]
        for (j, h) in head.enumerated() { out[h] = j < r.count ? r[j] : "" }
        return out
    }
}
