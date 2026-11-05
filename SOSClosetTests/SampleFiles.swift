import Foundation
@testable import SOSCloset

/// The sample store, read from this repo's SampleStore/ folder (copied in by tools/sync-sample-store.sh and
/// git-ignored), the way the app reads it: the site's test/sample-catalog.ts. Tests that need it are skipped when the
/// folder isn't there.
nonisolated enum SampleFiles {
    /// The repo's folder (this file is in SOSClosetTests/).
    static let repo = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    static let folder = repo.appending(path: "SampleStore")

    static var available: Bool {
        ["data/shopify-products.csv", "data/product-images.csv", "data/photo-fit.json", "data/catalog.json", "data/merch.json"]
            .allSatisfy { FileManager.default.fileExists(atPath: folder.appending(path: $0).path(percentEncoded: false)) }
    }

    /// The sample store as the app builds it: the import files, the photo sizes and data/merch.json's stand-ins.
    static let catalog: SourceCatalog =
        (try? SampleStoreSource(folder: folder).read()) ?? SourceCatalog(records: [], roomLists: [:])
    static var records: [ProductRecord] { catalog.records }
    static let pieces: [Piece] = closetOf(catalog.records)

    static func record(_ handle: String) -> ProductRecord {
        records.first { $0.handle == handle }!
    }

    /// data/catalog.json: the prototype's data, the oracle the sample store is checked against.
    nonisolated struct CatalogJSON: Decodable, Sendable {
        var items: [Item]

        nonisolated struct Item: Decodable, Sendable {
            var id: String
            var s: String
            var c: String
            var sub: String
            var b: String
            var t: String
            var d: String
            var p: Double
            var sz: [String]?
            var col: [String]
            var tg: [String]?
            var nd: Bool?
        }
    }

    static let catalogJSON: CatalogJSON = {
        guard let data = try? Data(contentsOf: folder.appending(path: "data/catalog.json")),
            let json = try? JSONDecoder().decode(CatalogJSON.self, from: data)
        else { return CatalogJSON(items: []) }
        return json
    }()

    static let merch: SampleMerch? = {
        guard let data = try? Data(contentsOf: folder.appending(path: "data/merch.json")) else { return nil }
        return try? JSONDecoder().decode(SampleMerch.self, from: data)
    }()
}

nonisolated extension Piece {
    /// A piece with only an id and handle, for order tests.
    static func stub(_ id: String, handle: String? = nil) -> Piece {
        Piece(
            id: id, handle: handle ?? id, dept: nil, cat: nil, sub: nil, designer: "", noDesigner: false, title: "",
            detail: "", price: 0, sizes: [], ax: nil, fz: [], fnote: nil, colors: [], tags: [], authenticated: false,
            image: nil, morePhotos: nil, fit: nil, story: nil)
    }
}
