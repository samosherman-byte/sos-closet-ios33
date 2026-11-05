import Foundation

// Where the closet comes from (APP-SPEC §3.1, §5): Sam's store through the Storefront API (StorefrontSource), or the
// site's sample store in Debug builds (SampleStoreSource). Both give the same ProductRecords, which go through the same
// mapper (Record.swift), as on the site (app/lib/catalog/index.server.ts).

/// What a source gives for the whole closet: every product for sale, and each home room's collection (its products'
/// handles, in the collection's order).
nonisolated struct SourceCatalog: Sendable {
    var records: [ProductRecord]
    /// By collection handle. Empty when the source can't say (the rooms are then left out; the page still shows).
    var roomLists: [String: [String]]
}

nonisolated protocol CatalogSource: Sendable {
    /// Every product for sale, and the products of these collections (the home page's "Home row" collections).
    func catalog(roomCollections: [String]) async throws -> SourceCatalog

    /// One product with everything its page shows, a sold one too; nil when the store has no such product. `records`
    /// is the closet as last loaded (the sample store's records already carry everything; Shopify is asked again).
    func product(handle: String, in records: [ProductRecord]) async throws -> ProductRecord?
}

/// Why the closet couldn't load, in words for the screen.
nonisolated enum CatalogError: LocalizedError, Equatable, Sendable {
    /// No store address or Storefront token in this build (Config/Secrets.xcconfig isn't filled in yet).
    case notConfigured
    /// A Debug build reading the sample store, without SampleStore/ (tools/sync-sample-store.sh hasn't run).
    case sampleStoreMissing
    /// The iPhone is offline.
    case offline
    /// Shopify couldn't be reached (timed out, or another network failure).
    case unreachable
    /// Shopify turned the token away (401 or 403).
    case refused(status: Int)
    /// Shopify answered with an error page.
    case server(status: Int)
    /// Shopify answered with GraphQL errors.
    case store(messages: [String])
    /// Shopify's answer wasn't what the query asks for.
    case unreadable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            "The store isn’t connected in this build yet: its address and Storefront token go in Config/Secrets.xcconfig."
        case .sampleStoreMissing:
            "The sample store isn’t in this build. Run tools/sync-sample-store.sh, then build again."
        case .offline:
            "You’re offline. Connect to the internet, then pull down to try again."
        case .unreachable:
            "The store can’t be reached right now. Pull down to try again."
        case .refused:
            "The store turned this app’s token away. Check the Storefront token in Config/Secrets.xcconfig."
        case .server(let status):
            "The store couldn’t answer right now (error \(status)). Pull down to try again."
        case .store(let messages):
            "The store couldn’t answer: \(messages.first ?? "unknown error")"
        case .unreadable:
            "The store’s answer couldn’t be read. Pull down to try again."
        }
    }

    /// The words for any error a load can end with.
    static func message(for error: any Error) -> String {
        if let e = error as? CatalogError { return e.errorDescription ?? "The closet couldn’t load." }
        if let e = error as? URLError { return CatalogError(e).errorDescription ?? "The closet couldn’t load." }
        if error is DecodingError { return CatalogError.unreadable.errorDescription ?? "" }
        return "The closet couldn’t load. Pull down to try again."
    }

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .dataNotAllowed, .internationalRoamingOff: self = .offline
        default: self = .unreachable
        }
    }
}

/// A source that can't give anything, and says why (a build with no store to read).
nonisolated struct UnavailableSource: CatalogSource {
    var error: CatalogError

    func catalog(roomCollections: [String]) async throws -> SourceCatalog { throw error }
    func product(handle: String, in records: [ProductRecord]) async throws -> ProductRecord? { throw error }
}
