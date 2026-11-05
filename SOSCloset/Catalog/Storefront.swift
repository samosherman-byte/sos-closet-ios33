import Foundation

// Sam's store through Shopify's Storefront API (APP-SPEC §3.1, §5), ported from the site's
// app/lib/catalog/shopify.server.ts: the same queries (the same fields, the same @inContext, the same page sizes) and
// the same mapping from Shopify's answer to a ProductRecord. Plain URLSession: POST the query text to
// StoreConfig.endpoint with the public token in X-Shopify-Storefront-Access-Token.

nonisolated enum StorefrontQueries {
    // Every piece for sale, for browse pages, menus, search and Saved. Sold pieces (nothing left to sell) are left out
    // by the query and again by the mapper. Each comes with all its photos in Shopify's order, the cover first (up to
    // 20, as on its page). A piece in a small department's case carries a story line (SPEC §7): its sos.story
    // metafield, or the first sentence of its description (`summary`, the description's start as plain text).
    static let catalogProduct = """
        fragment CatalogProduct on Product {
          id
          handle
          title
          vendor
          productType
          tags
          createdAt
          images(first: 20) {
            nodes {
              url
              altText
              width
              height
            }
          }
          media(first: 1) {
            nodes {
              id
            }
          }
          variants(first: 10) {
            nodes {
              id
              availableForSale
              price {
                amount
              }
              selectedOptions {
                name
                value
              }
            }
          }
          detailLine: metafield(namespace: "custom", key: "detail_line") {
            value
          }
          authenticated: metafield(namespace: "custom", key: "authenticated") {
            value
          }
          placeAfter: metafield(namespace: "custom", key: "place_after") {
            reference {
              ... on Product {
                handle
              }
            }
          }
          photoFit: metafield(namespace: "sos", key: "photo_fit") {
            value
          }
          story: metafield(namespace: "sos", key: "story") {
            value
          }
          summary: description(truncateAt: 200)
        }
        """

    static let catalog = """
        query Catalog($cursor: String, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          products(first: 250, after: $cursor, query: "available_for_sale:true", sortKey: CREATED_AT, reverse: true) {
            nodes {
              ...CatalogProduct
            }
            pageInfo {
              hasNextPage
              endCursor
            }
          }
        }
        \(catalogProduct)
        """

    static let productDetail = """
        query ProductDetail($handle: String!, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          product(handle: $handle) {
            id
            handle
            title
            vendor
            productType
            tags
            createdAt
            descriptionHtml
            seo {
              title
              description
            }
            images(first: 20) {
              nodes {
                url
                altText
                width
                height
              }
            }
            variants(first: 50) {
              nodes {
                id
                availableForSale
                price {
                  amount
                }
                selectedOptions {
                  name
                  value
                }
              }
            }
            detailLine: metafield(namespace: "custom", key: "detail_line") {
              value
            }
            authenticated: metafield(namespace: "custom", key: "authenticated") {
              value
            }
            colorName: metafield(namespace: "custom", key: "color_name") {
              value
            }
            swatch: metafield(namespace: "custom", key: "swatch") {
              value
            }
            details: metafield(namespace: "custom", key: "details") {
              value
            }
          }
        }
        """

    // The home page's rooms (SPEC §11a): each room's "Home row" collection, its products in the collection's own order
    // (the manual order Sam drags them into in the admin). Only their handles: the pieces themselves are the closet's.
    // A room has a few; the first 20 leaves room for spares behind ones that have sold.
    static let homeRoom = """
        fragment HomeRoom on Collection {
          products(first: 20) {
            nodes {
              handle
            }
          }
        }
        """

    /// One alias for each collection, so however many rooms there are it's one round trip to Shopify.
    static func homeRooms(_ collections: [String]) -> String {
        let fields = collections.enumerated().map { i, c in
            "  c\(i): collection(handle: \(jsonString(c))) {\n    ...HomeRoom\n  }"
        }
        return "query HomeRooms {\n\(fields.joined(separator: "\n"))\n}\n\(homeRoom)"
    }

    /// A string as JSON writes it (JSON.stringify): quoted and escaped, as GraphQL reads a string.
    static func jsonString(_ s: String) -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.withoutEscapingSlashes]
        return (try? encoder.encode(s)).flatMap { String(data: $0, encoding: .utf8) } ?? "\"\""
    }

    /// Products per page (the most the Storefront API gives at once: the closet comes in one request) and at most how
    /// many pages, as on the site.
    static let pageSize = 250
    static let maxPages = 20
}

/// Shopify's answer, as the queries above ask for it.
nonisolated enum StorefrontAPI {
    nonisolated struct Response<T: Decodable & Sendable>: Decodable, Sendable {
        var data: T?
        var errors: [Message]?
    }

    nonisolated struct Message: Decodable, Sendable {
        var message: String
    }

    nonisolated struct Nodes<T: Decodable & Sendable>: Decodable, Sendable {
        var nodes: [T]
    }

    nonisolated struct PageInfo: Decodable, Sendable {
        var hasNextPage: Bool
        var endCursor: String?
    }

    nonisolated struct ProductPage: Decodable, Sendable {
        var nodes: [Product]
        var pageInfo: PageInfo
    }

    nonisolated struct CatalogData: Decodable, Sendable {
        var products: ProductPage
    }

    nonisolated struct ProductData: Decodable, Sendable {
        var product: Product?
    }

    nonisolated struct Image: Decodable, Sendable {
        var url: String
        var altText: String?
        var width: Int?
        var height: Int?
    }

    nonisolated struct MediaID: Decodable, Sendable {
        var id: String
    }

    /// Shopify's Decimal is text ("295.0"); a number is read too.
    nonisolated struct Money: Decodable, Sendable {
        var amount: Double

        nonisolated enum CodingKeys: String, CodingKey { case amount }

        init(from decoder: any Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            if let text = try? c.decode(String.self, forKey: .amount) {
                amount = jsNumber(text)
            } else {
                amount = try c.decode(Double.self, forKey: .amount)
            }
        }
    }

    nonisolated struct Option: Decodable, Sendable {
        var name: String
        var value: String
    }

    nonisolated struct Variant: Decodable, Sendable {
        var id: String
        var availableForSale: Bool
        var price: Money
        var selectedOptions: [Option]
    }

    nonisolated struct Value: Decodable, Sendable {
        var value: String?
    }

    nonisolated struct Reference: Decodable, Sendable {
        var reference: Handle?
    }

    nonisolated struct Handle: Decodable, Sendable {
        var handle: String?
    }

    nonisolated struct SEO: Decodable, Sendable {
        var title: String?
        var description: String?
    }

    /// A product, from either query (the fields one query doesn't ask for are nil).
    nonisolated struct Product: Decodable, Sendable {
        var id: String
        var handle: String
        var title: String
        var vendor: String
        var productType: String
        var tags: [String]
        var createdAt: String
        var descriptionHtml: String?
        var summary: String?
        var seo: SEO?
        var images: Nodes<Image>
        var media: Nodes<MediaID>?
        var variants: Nodes<Variant>
        var detailLine: Value?
        var authenticated: Value?
        var colorName: Value?
        var swatch: Value?
        var details: Value?
        var placeAfter: Reference?
        var photoFit: Value?
        var story: Value?
    }

    nonisolated struct Collection: Decodable, Sendable {
        var products: Nodes<Handle>
    }
}

/// From Shopify's answer to a ProductRecord (shopify.server.ts `image`, `variant`, `catalogRecord` and the end of
/// `shopifyProduct`).
nonisolated enum StorefrontMapping {
    static func image(_ i: StorefrontAPI.Image) -> PieceImage? {
        guard let url = URL(string: i.url) else { return nil }
        return PieceImage(url: url, alt: i.altText ?? "", width: i.width, height: i.height)
    }

    static func variant(_ v: StorefrontAPI.Variant) -> Variant {
        Variant(
            id: v.id,
            size: v.selectedOptions.first { $0.name.lowercased() == "size" }?.value,
            available: v.availableForSale,
            price: v.price.amount
        )
    }

    /// A product from the catalog query.
    static func catalogRecord(_ p: StorefrontAPI.Product) -> ProductRecord {
        ProductRecord(
            productId: p.id,
            handle: p.handle,
            title: p.title,
            vendor: p.vendor,
            productType: p.productType,
            tags: p.tags,
            createdAt: p.createdAt,
            descriptionHtml: "",
            summary: p.summary,
            images: p.images.nodes.compactMap(image),
            coverId: p.media?.nodes.first?.id,
            variants: p.variants.nodes.map(variant),
            metafields: .init(
                detailLine: p.detailLine?.value,
                authenticated: p.authenticated?.value == "true",
                placeAfter: p.placeAfter?.reference?.handle,
                photoFit: p.photoFit?.value,
                story: p.story?.value
            )
        )
    }

    /// A product from the product page's query.
    static func detailRecord(_ p: StorefrontAPI.Product) -> ProductRecord {
        ProductRecord(
            productId: p.id,
            handle: p.handle,
            title: p.title,
            vendor: p.vendor,
            productType: p.productType,
            tags: p.tags,
            createdAt: p.createdAt,
            descriptionHtml: p.descriptionHtml ?? "",
            images: p.images.nodes.compactMap(image),
            variants: p.variants.nodes.map(variant),
            metafields: .init(
                detailLine: p.detailLine?.value,
                authenticated: p.authenticated?.value == "true",
                colorName: p.colorName?.value,
                swatch: p.swatch?.value,
                details: (p.details?.value ?? "").components(separatedBy: "\n").map(\.jsTrimmed).filter { !$0.isEmpty }
            ),
            seoTitle: p.seo?.title,
            seoDescription: p.seo?.description
        )
    }
}

/// Sam's store through the Storefront API.
nonisolated struct StorefrontSource: CatalogSource {
    /// Sends a request and gives back Shopify's answer (URLSession; the tests stand in their own).
    typealias Transport = @Sendable (URLRequest) async throws -> (Data, URLResponse)

    /// `StoreConfig.endpoint`: nil until the store's address is in Config/Secrets.xcconfig.
    var endpoint: URL?
    /// The public Storefront token (`StoreConfig.storefrontToken`).
    var token: String
    /// The site's @inContext (Hydrogen's i18n in the site's app/lib/context.ts): the United States, in English.
    var country = "US"
    var language = "EN"
    var transport: Transport

    init(
        endpoint: URL? = StoreConfig.endpoint, token: String = StoreConfig.storefrontToken,
        transport: @escaping Transport = StorefrontSource.urlSession
    ) {
        self.endpoint = endpoint
        self.token = token
        self.transport = transport
    }

    static let urlSession: Transport = { request in
        try await URLSession.shared.data(for: request)
    }

    // MARK: CatalogSource

    func catalog(roomCollections: [String]) async throws -> SourceCatalog {
        // (Both at once, as the site does. If Shopify can't say what's in the collections, the rooms are left out.)
        async let lists = roomListsOrNone(roomCollections)
        let products = try await records()
        return SourceCatalog(records: products, roomLists: await lists)
    }

    func product(handle: String, in records: [ProductRecord]) async throws -> ProductRecord? {
        try await product(handle: handle)
    }

    // MARK: The queries

    /// Every product for sale, newest listing first, paged until done (shopify.server.ts `shopifyRecords`).
    func records() async throws -> [ProductRecord] {
        var out: [ProductRecord] = []
        var cursor: String?
        for _ in 0..<StorefrontQueries.maxPages {
            let data: StorefrontAPI.CatalogData = try await query(
                StorefrontQueries.catalog, variables: ["cursor": cursor.map { .string($0) } ?? .null])
            out += data.products.nodes.map(StorefrontMapping.catalogRecord)
            guard data.products.pageInfo.hasNextPage else { break }
            cursor = data.products.pageInfo.endCursor
        }
        return out
    }

    /// Each collection's products (handles, in its order), all the collections in one request. A collection that
    /// doesn't exist, or isn't on the app's sales channel, has none (shopify.server.ts `shopifyCollectionHandles`).
    func collectionHandles(_ collections: [String]) async throws -> [String: [String]] {
        guard !collections.isEmpty else { return [:] }
        let data: [String: StorefrontAPI.Collection?] = try await query(
            StorefrontQueries.homeRooms(collections), variables: nil)
        var out: [String: [String]] = [:]
        for (i, c) in collections.enumerated() {
            out[c] = (data["c\(i)"] ?? nil)?.products.nodes.compactMap(\.handle) ?? []
        }
        return out
    }

    /// One product with everything its page shows, or nil when the store has none by that handle
    /// (shopify.server.ts `shopifyProduct`).
    func product(handle: String) async throws -> ProductRecord? {
        let data: StorefrontAPI.ProductData = try await query(
            StorefrontQueries.productDetail, variables: ["handle": .string(handle)])
        return data.product.map(StorefrontMapping.detailRecord)
    }

    private func roomListsOrNone(_ collections: [String]) async -> [String: [String]] {
        (try? await collectionHandles(collections)) ?? [:]
    }

    // MARK: Sending a query

    /// A GraphQL variable's value.
    nonisolated enum Variable: Encodable, Sendable {
        case string(String)
        case null

        func encode(to encoder: any Encoder) throws {
            var c = encoder.singleValueContainer()
            switch self {
            case .string(let s): try c.encode(s)
            case .null: try c.encodeNil()
            }
        }
    }

    private nonisolated struct Body: Encodable {
        var query: String
        var variables: [String: Variable]?
    }

    /// The request for a query: POST to the endpoint, with the token. Variables given, the site's country and
    /// language come too (the queries that declare them use them for @inContext).
    func request(_ query: String, variables: [String: Variable]?) throws -> URLRequest {
        guard let endpoint, !token.isEmpty else { throw CatalogError.notConfigured }
        var request = URLRequest(url: endpoint, timeoutInterval: 30)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(token, forHTTPHeaderField: "X-Shopify-Storefront-Access-Token")
        var vars = variables
        if vars != nil {
            vars!["country"] = .string(country)
            vars!["language"] = .string(language)
        }
        request.httpBody = try JSONEncoder().encode(Body(query: query, variables: vars))
        return request
    }

    func query<T: Decodable & Sendable>(_ query: String, variables: [String: Variable]?) async throws -> T {
        let request = try request(query, variables: variables)
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await transport(request)
        } catch let error as URLError {
            throw CatalogError(error)
        }
        return try Self.decode(data, response: response)
    }

    /// Shopify's answer to a query, or why there isn't one.
    static func decode<T: Decodable & Sendable>(_ data: Data, response: URLResponse?) throws -> T {
        if let http = response as? HTTPURLResponse, !(200..<300).contains(http.statusCode) {
            throw http.statusCode == 401 || http.statusCode == 403
                ? CatalogError.refused(status: http.statusCode) : CatalogError.server(status: http.statusCode)
        }
        let answer: StorefrontAPI.Response<T>
        do {
            answer = try JSONDecoder().decode(StorefrontAPI.Response<T>.self, from: data)
        } catch {
            throw CatalogError.unreadable
        }
        if let errors = answer.errors, !errors.isEmpty { throw CatalogError.store(messages: errors.map(\.message)) }
        guard let result = answer.data else { throw CatalogError.unreadable }
        return result
    }
}
