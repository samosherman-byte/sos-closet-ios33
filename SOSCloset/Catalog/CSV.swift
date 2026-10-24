import Foundation

/// Reads a CSV file the way Shopify's import does (RFC 4180): fields in double quotes may hold commas, line breaks
/// and doubled quotes (`""`). Used for the sample store's import files, which are the files Sam imports into Shopify.
nonisolated enum CSV {
    /// Every row as a dictionary keyed by the header row. Rows shorter than the header get empty fields.
    static func records(_ text: String) -> [[String: String]] {
        var rows = parse(text)
        guard !rows.isEmpty else { return [] }
        let header = rows.removeFirst()
        return rows.map { row in
            Dictionary(uniqueKeysWithValues: header.enumerated().map { index, key in
                (key, index < row.count ? row[index] : "")
            })
        }
    }

    static func parse(_ text: String) -> [[String]] {
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var iterator = text.unicodeScalars.makeIterator()
        var pending: Unicode.Scalar? = nil

        func endField() { row.append(field); field = "" }
        func endRow() {
            endField()
            if !(row.count == 1 && row[0].isEmpty) { rows.append(row) }
            row = []
        }

        while let scalar = pending ?? iterator.next() {
            pending = nil
            if quoted {
                if scalar == "\"" {
                    let next = iterator.next()
                    if next == "\"" { field.unicodeScalars.append("\"") } else { quoted = false; pending = next }
                } else {
                    field.unicodeScalars.append(scalar)
                }
                continue
            }
            switch scalar {
            case "\"": quoted = true
            case ",": endField()
            case "\r":
                let next = iterator.next()
                if next != "\n" { pending = next }
                endRow()
            case "\n": endRow()
            default: field.unicodeScalars.append(scalar)
            }
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }
}
