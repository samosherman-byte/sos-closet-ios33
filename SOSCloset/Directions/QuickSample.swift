import Foundation

/// TEMPORARY, for the two navigation directions only (branch nav/directions): just enough of the sample store to
/// fill the quick screens with real pieces. The real mapping (the site's record.ts and order.ts, line for line,
/// with their tests) comes with data/catalog and replaces this file.
nonisolated struct QuickPiece: Identifiable, Hashable, Sendable {
    let id: String
    let designer: String
    let name: String
    let price: Decimal
    let sizes: [String]
    let place: Place
    let category: String
    let photo: URL?
}

nonisolated enum QuickSample {
    static let pieces: [QuickPiece] = load()

    /// The categories of a department, in its tile row's order (the site's `CATS`), and each one's cutout.
    static let categories: [Place: [(name: String, tile: String)]] = [
        .women: [("Handbags", "women-handbags"), ("Clothing", "women-clothing"), ("Shoes", "women-shoes"), ("Accessories", "women-accessories")],
        .men: [("Clothing", "men-clothing"), ("Shoes", "men-shoes"), ("Accessories", "men-accessories")],
        .jewelry: [("Jewelry", "jewelry-jewelry"), ("Watches", "jewelry-watches")],
        .artHome: [("Art", "home-art"), ("Home", "home-home")],
    ]

    static func pieces(in place: Place) -> [QuickPiece] {
        pieces.filter { $0.place == place }
    }

    static func pieces(in place: Place, category: String) -> [QuickPiece] {
        pieces.filter { $0.place == place && $0.category == category }
    }

    private static func load() -> [QuickPiece] {
        guard let store = StoreConfig.sampleStoreURL,
              let products = try? String(contentsOf: store.appending(path: "data/shopify-products.csv"), encoding: .utf8),
              let images = try? String(contentsOf: store.appending(path: "data/product-images.csv"), encoding: .utf8)
        else { return [] }

        var covers: [String: URL] = [:]
        for row in CSV.records(images) where row["Position"] == "1" {
            if let handle = row["Handle"], let file = row["File"] { covers[handle] = store.appending(path: file) }
        }

        // The import file has one row per variant (and per extra photo); the first row of a handle carries the product.
        var order: [String] = []
        var first: [String: [String: String]] = [:]
        var variants: [String: [(price: Decimal, size: String?, inStock: Bool)]] = [:]
        for row in CSV.records(products) {
            guard let handle = row["Handle"], !handle.isEmpty else { continue }
            if first[handle] == nil { first[handle] = row; order.append(handle) }
            guard let price = Decimal(string: row["Variant Price"] ?? ""), !(row["Variant Price"] ?? "").isEmpty else { continue }
            let optionName = first[handle]?["Option1 Name"] ?? ""
            let size = optionName == "Size" ? row["Option1 Value"] : nil
            let inStock = (Int(row["Variant Inventory Qty"] ?? "") ?? 0) > 0
            variants[handle, default: []].append((price, size, inStock))
        }

        return order.compactMap { handle in
            guard let row = first[handle], row["Status"] != "archived" else { return nil }
            let tags = (row["Tags"] ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let dept = tags.first(where: { $0.hasPrefix("dept:") }).map({ String($0.dropFirst(5)) }),
                  let place = Place(deptKey: dept)
            else { return nil }
            let forSale = (variants[handle] ?? []).filter(\.inStock)
            guard let price = forSale.map(\.price).min() else { return nil }
            return QuickPiece(
                id: handle,
                designer: row["Vendor"] ?? "",
                name: row["Title"] ?? "",
                price: price,
                sizes: forSale.compactMap(\.size),
                place: place,
                category: row["Type"] ?? "",
                photo: covers[handle]
            )
        }
    }
}

extension Decimal {
    /// "$1,250"; cents only when there are some ("$1,250.50").
    var priceText: String {
        let whole = self == Decimal(Int(truncating: self as NSNumber))
        return formatted(.currency(code: "USD").precision(.fractionLength(whole ? 0 : 2)))
    }
}
