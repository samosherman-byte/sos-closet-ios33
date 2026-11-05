import Foundation

// The sample store (APP-SPEC §5), ported from the site's app/lib/catalog/sample.ts: the same import files Sam imports
// into Shopify (data/shopify-products.csv and data/product-images.csv), read as Shopify would deliver them, with the
// photo size standard measured on their covers (data/photo-fit.json, as the live store keeps it in each product's
// sos.photo_fit metafield), and data/merch.json's stand-ins for what the live store keeps in Shopify (the case's story
// lines and featured piece, the home page's "Home row" collections). tools/sync-sample-store.sh copies them into
// SampleStore/; Debug builds reading the sample store carry that folder. Development and tests only.

nonisolated enum SampleStoreFiles {
    /// The import gives every product the same created date (sample.ts `IMPORTED_AT`).
    static let importedAt = "2026-10-01T00:00:00Z"
    /// The end of a metafield's column header in the import file (sample.ts `META`).
    static func metafieldColumn(_ key: String) -> String { "(product.metafields.custom.\(key))" }
}

/// Each product's sos.photo_fit value as the live store keeps it (text), from data/photo-fit.json's `fits`.
nonisolated func photoFitValues(fromJSON data: Data) -> [String: String] {
    guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
        let fits = root["fits"] as? [String: Any]
    else { return [:] }
    var out: [String: String] = [:]
    for (handle, fit) in fits {
        guard JSONSerialization.isValidJSONObject(fit), let d = try? JSONSerialization.data(withJSONObject: fit),
            let text = String(data: d, encoding: .utf8)
        else { continue }
        out[handle] = text
    }
    return out
}

/// The products in the import files, as Shopify would deliver them (sample.ts `recordsFromCsv`). `fits`: each
/// product's sos.photo_fit value by handle. `imageFolder`: where the photos are (the import file names them as
/// prototype/img/<file>; the site serves them at /__sample/img/<file>, the app reads them from its SampleStore folder).
nonisolated func recordsFromCsv(
    _ productsCsv: String, _ imagesCsv: String, fits: [String: String] = [:], imageFolder: URL
) -> [ProductRecord] {
    var photos: [String: [PieceImage]] = [:]
    let imageRows = parseCsv(imagesCsv).stableSorted { jsNumber($0["Position"] ?? "") < jsNumber($1["Position"] ?? "") }
    for r in imageRows {
        let handle = r["Handle"] ?? ""
        let file = (r["File"] ?? "").components(separatedBy: "/").last ?? ""
        photos[handle, default: []].append(
            PieceImage(url: imageFolder.appending(path: file), alt: r["Alt Text"] ?? "", width: 1200, height: 1500))
    }

    var out: [ProductRecord] = []
    var columns: [String: String] = [:]
    func metafield(_ row: [String: String], _ key: String) -> String {
        let column = columns[key] ?? row.keys.first { $0.hasSuffix(SampleStoreFiles.metafieldColumn(key)) }
        columns[key] = column
        return column.flatMap { row[$0] } ?? ""
    }
    for r in parseCsv(productsCsv) {
        let handle = r["Handle"] ?? ""
        if !(r["Title"] ?? "").isEmpty {
            let details = metafield(r, "details")
            let images = photos[handle] ?? []
            out.append(
                ProductRecord(
                    handle: handle,
                    title: r["Title"] ?? "",
                    vendor: r["Vendor"] ?? "",
                    productType: r["Type"] ?? "",
                    tags: (r["Tags"] ?? "").components(separatedBy: ",").map(\.jsTrimmed).filter { !$0.isEmpty },
                    createdAt: SampleStoreFiles.importedAt,
                    descriptionHtml: r["Body (HTML)"] ?? "",
                    images: images,
                    coverId: images.first?.url.lastPathComponent,
                    variants: [],
                    metafields: .init(
                        detailLine: metafield(r, "detail_line").nilIfEmpty,
                        authenticated: metafield(r, "authenticated").lowercased() == "true",
                        colorName: metafield(r, "color_name").nilIfEmpty,
                        swatch: metafield(r, "swatch").nilIfEmpty,
                        details: details.isEmpty ? [] : details.components(separatedBy: "\n").filter { !$0.isEmpty },
                        placeAfter: nil,
                        photoFit: fits[handle]
                    ),
                    seoTitle: r["SEO Title"],
                    seoDescription: r["SEO Description"]
                ))
        }
        if let last = out.indices.last, handle == out[last].handle, !(r["Variant SKU"] ?? "").isEmpty {
            let name = r["Option1 Name"] ?? ""
            let value = r["Option1 Value"] ?? ""
            out[last].variants.append(
                Variant(
                    id: "sample:\(r["Variant SKU"] ?? "")",
                    size: name == "Title" || value == "Default Title" ? nil : value,
                    available: jsNumber(r["Variant Inventory Qty"] ?? "") > 0,
                    price: jsNumber(r["Variant Price"] ?? "")
                ))
        }
    }
    return out
}

/// The sample store's stand-ins for a case's Shopify data (SPEC §7, Without Shopify): data/merch.json's case, each
/// piece's story line (the sos.story metafield in the live store) and the piece that leads (tagged `featured` there),
/// by id (the Shopify tag id:<id>). sample.ts `caseStandIns`.
nonisolated func caseStandIns(_ records: [ProductRecord], featured: [String], story: [String: String]) -> [ProductRecord] {
    records.map { r in
        let id = parseTags(r.tags).id ?? r.handle
        let line = story[id]
        let leads = featured.contains(id)
        guard line != nil || leads else { return r }
        var out = r
        if leads { out.tags.append(Merch.featuredTag) }
        if let line { out.metafields.story = line }
        return out
    }
}

/// The sample store's "Home row" collections (SPEC §11a, Without Shopify): data/merch.json's home_page.rooms, each a
/// collection and its pieces by id, as handles in that order. A piece only in Shopify is left out.
/// sample.ts `sampleCollections`.
nonisolated func sampleCollections(
    _ rooms: [(collection: String, pieces: [String])], _ records: [ProductRecord]
) -> [String: [String]] {
    var handleOf: [String: String] = [:]
    for r in records {
        handleOf[r.handle] = r.handle
        if let id = parseTags(r.tags).id { handleOf[id] = r.handle }
    }
    var out: [String: [String]] = [:]
    for room in rooms { out[room.collection] = room.pieces.compactMap { handleOf[$0] } }
    return out
}

/// What the app reads of data/merch.json: the case's stand-ins and the home page's rooms.
nonisolated struct SampleMerch: Decodable, Sendable {
    var caseStandIns: CaseStandIns
    var homePage: HomePage

    nonisolated struct CaseStandIns: Decodable, Sendable {
        var featured: [String]
        var story: [String: String]
    }

    nonisolated struct HomePage: Decodable, Sendable {
        var rooms: [Room]
    }

    nonisolated struct Room: Decodable, Sendable {
        var collection: String
        var pieces: [String]
    }

    nonisolated enum CodingKeys: String, CodingKey {
        case caseStandIns = "case"
        case homePage = "home_page"
    }
}

/// The sample store in a folder laid out as tools/sync-sample-store.sh copies it: data/ and prototype/img/.
nonisolated struct SampleStoreSource: CatalogSource {
    /// The SampleStore folder (in the app, `StoreConfig.sampleStoreURL`; in the tests, the repo's own).
    var folder: URL

    var imageFolder: URL { folder.appending(path: "prototype/img") }

    /// Every product in the import files (sold ones too), with the stand-ins; and the home rooms' collections.
    func read() throws -> SourceCatalog {
        let data = folder.appending(path: "data")
        guard let products = try? String(contentsOf: data.appending(path: "shopify-products.csv"), encoding: .utf8),
            let images = try? String(contentsOf: data.appending(path: "product-images.csv"), encoding: .utf8)
        else { throw CatalogError.sampleStoreMissing }
        let fits = (try? Data(contentsOf: data.appending(path: "photo-fit.json"))).map(photoFitValues) ?? [:]
        var records = recordsFromCsv(products, images, fits: fits, imageFolder: imageFolder)
        // (data/merch.json came with the sample store from November 5: without it, no story lines or rooms.)
        guard let merchData = try? Data(contentsOf: data.appending(path: "merch.json")),
            let merch = try? JSONDecoder().decode(SampleMerch.self, from: merchData)
        else { return SourceCatalog(records: records, roomLists: [:]) }
        records = caseStandIns(records, featured: merch.caseStandIns.featured, story: merch.caseStandIns.story)
        let rooms = merch.homePage.rooms.map { (collection: $0.collection, pieces: $0.pieces) }
        return SourceCatalog(records: records, roomLists: sampleCollections(rooms, records))
    }

    func catalog(roomCollections: [String]) async throws -> SourceCatalog {
        try read()
    }

    func product(handle: String, in records: [ProductRecord]) async throws -> ProductRecord? {
        if let r = records.first(where: { $0.handle == handle }) { return r }
        return try read().records.first { $0.handle == handle }
    }
}

nonisolated extension String {
    /// Nil for "" (JavaScript's `value || null`).
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
