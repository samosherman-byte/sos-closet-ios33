import Foundation
import Testing
@testable import SOSCloset

// Shopify's answer → ProductRecord (shopify.server.ts's mapping), from small hand-written answers shaped like the
// queries' (no Shopify needed), and what the app sends: the endpoint, the token, the query and its variables, paging.

private nonisolated enum Fixtures {
    static let catalogPage = #"""
        {"data":{"products":{"nodes":[
          {"id":"gid://shopify/Product/1","handle":"gucci-jackie-1961-medium-tote","title":"Jackie 1961 Medium Tote",
           "vendor":"Gucci","productType":"Handbags",
           "tags":["dept:women","cat:handbags","sub:totes","color:green","id:jackie","Vintage"],
           "createdAt":"2026-10-20T15:00:00Z",
           "images":{"nodes":[
             {"url":"https://cdn.shopify.com/s/files/1/0001/files/jackie-01.jpg?v=1","altText":"Gucci Jackie 1961 Medium Tote","width":2000,"height":2500},
             {"url":"https://cdn.shopify.com/s/files/1/0001/files/jackie-02.jpg?v=1","altText":"Gucci Jackie 1961 Medium Tote – back","width":2000,"height":2500},
             {"url":"https://cdn.shopify.com/s/files/1/0001/files/jackie-03.jpg?v=1","altText":"Gucci Jackie 1961 Medium Tote – heat stamp","width":1600,"height":2000}]},
           "media":{"nodes":[{"id":"gid://shopify/MediaImage/11"}]},
           "variants":{"nodes":[{"id":"gid://shopify/ProductVariant/21","availableForSale":true,"price":{"amount":"1890.0"},
             "selectedOptions":[{"name":"Title","value":"Default Title"}]}]},
           "detailLine":{"value":"Emerald · Leather"},
           "authenticated":{"value":"true"},
           "placeAfter":null,
           "photoFit":{"value":"{\"scale\":0.83,\"drop\":11,\"top\":38.5,\"home\":{\"garment\":[90,5,14,1.05]},\"homeVersion\":4,\"imageId\":\"gid://shopify/MediaImage/11\"}"},
           "story":null,
           "summary":"A Gucci Jackie 1961 tote in emerald leather. With its dust bag."},
          {"id":"gid://shopify/Product/2","handle":"coppley-suit","title":"Custom Windowpane Suit","vendor":"Coppley",
           "productType":"Clothing","tags":["dept:men","cat:clothing","sub:suits","color:beige","New with tags"],
           "createdAt":"2026-10-21T15:00:00Z",
           "images":{"nodes":[]},
           "media":{"nodes":[]},
           "variants":{"nodes":[
             {"id":"v40","availableForSale":false,"price":{"amount":"1200.0"},"selectedOptions":[{"name":"Size","value":"40R"}]},
             {"id":"v42","availableForSale":true,"price":{"amount":"1150.5"},"selectedOptions":[{"name":"Size","value":"42R"}]}]},
           "detailLine":null,"authenticated":null,
           "placeAfter":{"reference":{"handle":"gucci-jackie-1961-medium-tote"}},
           "photoFit":null,"story":{"value":"Its own line."},"summary":""},
          {"id":"gid://shopify/Product/3","handle":"odd-reference","title":"Odd","vendor":"V","productType":"Art",
           "tags":[],"createdAt":"2026-10-22T15:00:00Z","images":{"nodes":[]},"media":{"nodes":[]},
           "variants":{"nodes":[]},"placeAfter":{"reference":{}},"summary":""}
        ],"pageInfo":{"hasNextPage":false,"endCursor":"c3"}}}}
        """#

    static let productDetail = #"""
        {"data":{"product":{"id":"gid://shopify/Product/1","handle":"gucci-jackie-1961-medium-tote",
          "title":"Jackie 1961 Medium Tote","vendor":"Gucci","productType":"Handbags","tags":["dept:women","condition:excellent"],
          "createdAt":"2026-10-20T15:00:00Z","descriptionHtml":"<p>Emerald leather.</p>",
          "seo":{"title":null,"description":"A Gucci tote."},
          "images":{"nodes":[{"url":"https://cdn.shopify.com/a.jpg","altText":null,"width":null,"height":null}]},
          "variants":{"nodes":[{"id":"v1","availableForSale":false,"price":{"amount":"1890.0"},"selectedOptions":[]}]},
          "detailLine":{"value":"Emerald"},"authenticated":{"value":"false"},
          "colorName":{"value":"Emerald green"},"swatch":{"value":"#1F5A3E"},
          "details":{"value":" Leather \n\nGold-tone hardware\n "}}}}
        """#

    static let rooms = #"""
        {"data":{"c0":{"products":{"nodes":[{"handle":"a"},{"handle":"b"}]}},"c1":null}}
        """#

    static func page(_ handles: [String], next: String?) -> String {
        let nodes = handles.map { h in
            #"{"id":"gid://shopify/Product/\#(h)","handle":"\#(h)","title":"\#(h)","vendor":"V","productType":"Handbags","tags":[],"createdAt":"2026-10-20T00:00:00Z","images":{"nodes":[]},"media":{"nodes":[]},"variants":{"nodes":[{"id":"v","availableForSale":true,"price":{"amount":"10.0"},"selectedOptions":[]}]},"summary":""}"#
        }
        let info = next.map { #"{"hasNextPage":true,"endCursor":"\#($0)"}"# } ?? #"{"hasNextPage":false,"endCursor":null}"#
        return #"{"data":{"products":{"nodes":[\#(nodes.joined(separator: ","))],"pageInfo":\#(info)}}}"#
    }
}

/// Requests the stand-in transport was sent, and the answers it gives, in order.
private actor FakeShopify {
    var requests: [URLRequest] = []
    var answers: [(Int, String)]

    init(_ answers: [(Int, String)]) { self.answers = answers }

    func answer(_ request: URLRequest) -> (Data, URLResponse) {
        requests.append(request)
        let (status, body) = answers.isEmpty ? (200, "{}") : answers.removeFirst()
        let response = HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: nil)!
        return (Data(body.utf8), response)
    }

    /// What each request sent, as JSON.
    nonisolated func bodies() async -> [[String: Any]] {
        await requests.map { (try? JSONSerialization.jsonObject(with: $0.httpBody ?? Data())) as? [String: Any] ?? [:] }
    }
}

private func source(_ shop: FakeShopify) -> StorefrontSource {
    StorefrontSource(
        endpoint: URL(string: "https://example-store.myshopify.com/api/2026-10/graphql.json"), token: "public-test-token",
        transport: { request in await shop.answer(request) })
}

private func decode<T: Decodable & Sendable>(_ text: String) throws -> T {
    try StorefrontSource.decode(Data(text.utf8), response: nil)
}

@Suite("Shopify's answer → ProductRecord")
struct StorefrontDecodingTests {
    @Test func aCatalogPageMapsAsTheSiteMapsIt() throws {
        let data: StorefrontAPI.CatalogData = try decode(Fixtures.catalogPage)
        #expect(data.products.pageInfo.hasNextPage == false)
        let records = data.products.nodes.map(StorefrontMapping.catalogRecord)
        #expect(records.map(\.handle) == ["gucci-jackie-1961-medium-tote", "coppley-suit", "odd-reference"])

        let jackie = records[0]
        #expect(jackie.productId == "gid://shopify/Product/1")
        #expect(jackie.vendor == "Gucci")
        #expect(jackie.productType == "Handbags")
        #expect(jackie.tags.contains("id:jackie"))
        #expect(jackie.createdAt == "2026-10-20T15:00:00Z")
        #expect(jackie.descriptionHtml == "")
        #expect(jackie.summary == "A Gucci Jackie 1961 tote in emerald leather. With its dust bag.")
        #expect(jackie.images.count == 3)
        #expect(
            jackie.images[0]
                == PieceImage(
                    url: URL(string: "https://cdn.shopify.com/s/files/1/0001/files/jackie-01.jpg?v=1")!,
                    alt: "Gucci Jackie 1961 Medium Tote", width: 2000, height: 2500))
        #expect(jackie.coverId == "gid://shopify/MediaImage/11")
        #expect(jackie.variants == [Variant(id: "gid://shopify/ProductVariant/21", size: nil, available: true, price: 1890)])
        #expect(jackie.metafields.detailLine == "Emerald · Leather")
        #expect(jackie.metafields.authenticated)
        #expect(jackie.metafields.placeAfter == nil)
        #expect(jackie.metafields.story == nil)
        #expect(jackie.metafields.photoFit?.contains("\"imageId\":\"gid://shopify/MediaImage/11\"") == true)

        let suit = records[1]
        #expect(suit.variants.map(\.size) == ["40R", "42R"])
        #expect(suit.variants.map(\.available) == [false, true])
        #expect(suit.variants.map(\.price) == [1200, 1150.5])
        #expect(suit.metafields.detailLine == nil)
        #expect(!suit.metafields.authenticated)
        #expect(suit.metafields.placeAfter == "gucci-jackie-1961-medium-tote")
        #expect(suit.metafields.story == "Its own line.")
        #expect(suit.coverId == nil)
        // (A reference that isn't a product has no handle.)
        #expect(records[2].metafields.placeAfter == nil)
    }

    @Test func throughTheSameMapperAsTheSampleStore() throws {
        let data: StorefrontAPI.CatalogData = try decode(Fixtures.catalogPage)
        let records = data.products.nodes.map(StorefrontMapping.catalogRecord)
        let jackie = try #require(toPiece(records[0]))
        #expect(jackie.id == "jackie")
        #expect(jackie.dept == .women)
        #expect(jackie.cat == "Handbags")
        #expect(jackie.sub == "Totes")
        #expect(jackie.price == 1890)
        #expect(jackie.tags == ["Vintage"])
        #expect(jackie.fit == PhotoFit(scale: 0.83, drop: 11, top: 38.5))
        // The back is on the card; the heat stamp waits for the page.
        #expect(jackie.morePhotos?.map(\.url.lastPathComponent) == ["jackie-02.jpg"])
        #expect(homeFit(records[0].metafields.photoFit, coverId: records[0].coverId, kind: .garment) == HomeFit(width: 90, left: 5, top: 14, grow: 1.05))
        let suit = try #require(toPiece(records[1]))
        #expect(suit.sizes == ["42R"])
        #expect(suit.price == 1150.5)
        #expect(suit.ax == .mt)
        #expect(suit.fz == ["42R"])
        // Nothing for sale: gone.
        #expect(toPiece(records[2]) == nil)
        // The closet: newest first, the suit held back behind the Jackie (its own place_after), the odd one gone.
        #expect(closetOf(records).map(\.handle) == ["gucci-jackie-1961-medium-tote", "coppley-suit"])
    }

    @Test func aProductPageMapsAsTheSiteMapsIt() throws {
        let data: StorefrontAPI.ProductData = try decode(Fixtures.productDetail)
        let record = try #require(data.product.map(StorefrontMapping.detailRecord))
        #expect(record.descriptionHtml == "<p>Emerald leather.</p>")
        #expect(record.seoTitle == nil)
        #expect(record.seoDescription == "A Gucci tote.")
        #expect(record.metafields.colorName == "Emerald green")
        #expect(record.metafields.swatch == "#1F5A3E")
        #expect(record.metafields.details == ["Leather", "Gold-tone hardware"])
        #expect(!record.metafields.authenticated)
        #expect(record.images[0].alt == "")
        #expect(record.images[0].width == nil)
        // (The page's query has no media id, so no photo fit, as on the site.)
        #expect(record.coverId == nil)
        let page = try #require(toProductDetail(record))
        #expect(page.seoTitle == "Gucci Jackie 1961 Medium Tote")
        #expect(page.grade == .excellent)
        #expect(page.designer == "Gucci")
        // A sold piece keeps its page, with the price it was.
        #expect(page.price == 1890)
        #expect(page.sizes == [])
        let missing: StorefrontAPI.ProductData = try decode(#"{"data":{"product":null}}"#)
        #expect(missing.product == nil)
    }

    @Test func theRoomsCollectionsInTheirOrder() async throws {
        let shop = FakeShopify([(200, Fixtures.rooms)])
        let lists = try await source(shop).collectionHandles(["home-row-womens-clothing", "home-row-mens-clothing"])
        #expect(lists == ["home-row-womens-clothing": ["a", "b"], "home-row-mens-clothing": []])
        let query = try #require(await shop.bodies().first?["query"] as? String)
        #expect(query.contains(#"c0: collection(handle: "home-row-womens-clothing") {"#))
        #expect(query.contains(#"c1: collection(handle: "home-row-mens-clothing") {"#))
        #expect(query.contains("fragment HomeRoom on Collection"))
    }

    @Test func errorsInPlainWords() {
        #expect(throws: CatalogError.store(messages: ["Access denied"])) {
            let _: StorefrontAPI.CatalogData = try decode(#"{"errors":[{"message":"Access denied"}]}"#)
        }
        #expect(throws: CatalogError.unreadable) {
            let _: StorefrontAPI.CatalogData = try decode(#"{"data":{"products":{}}}"#)
        }
        #expect(throws: CatalogError.refused(status: 401)) {
            let _: StorefrontAPI.CatalogData = try StorefrontSource.decode(
                Data(), response: HTTPURLResponse(url: URL(string: "https://x")!, statusCode: 401, httpVersion: nil, headerFields: nil))
        }
        #expect(CatalogError.notConfigured.errorDescription?.contains("Config/Secrets.xcconfig") == true)
        #expect(CatalogError.message(for: URLError(.notConnectedToInternet)) == CatalogError.offline.errorDescription)
    }
}

@Suite("What the app sends Shopify")
struct StorefrontRequestTests {
    @Test func thePagedCatalogWithTheTokenAndTheSitesContext() async throws {
        let shop = FakeShopify([(200, Fixtures.page(["a", "b"], next: "p2")), (200, Fixtures.page(["c"], next: nil))])
        let records = try await source(shop).records()
        #expect(records.map(\.handle) == ["a", "b", "c"])

        let requests = await shop.requests
        #expect(requests.count == 2)
        let first = try #require(requests.first)
        #expect(first.httpMethod == "POST")
        #expect(first.url?.absoluteString == "https://example-store.myshopify.com/api/2026-10/graphql.json")
        #expect(first.value(forHTTPHeaderField: "X-Shopify-Storefront-Access-Token") == "public-test-token")
        #expect(first.value(forHTTPHeaderField: "Content-Type") == "application/json")

        let bodies = await shop.bodies()
        let query = try #require(bodies[0]["query"] as? String)
        #expect(query.contains("@inContext(country: $country, language: $language)"))
        #expect(query.contains(#"products(first: 250, after: $cursor, query: "available_for_sale:true", sortKey: CREATED_AT, reverse: true)"#))
        #expect(query.contains("fragment CatalogProduct on Product"))
        #expect(query.contains(#"photoFit: metafield(namespace: "sos", key: "photo_fit")"#))
        let vars0 = try #require(bodies[0]["variables"] as? [String: Any])
        #expect(vars0["cursor"] is NSNull)
        #expect(vars0["country"] as? String == "US")
        #expect(vars0["language"] as? String == "EN")
        let vars1 = try #require(bodies[1]["variables"] as? [String: Any])
        #expect(vars1["cursor"] as? String == "p2")
    }

    @Test func atMostTwentyPages() async throws {
        let shop = FakeShopify((0..<25).map { (200, Fixtures.page(["p\($0)"], next: "n\($0)")) })
        let records = try await source(shop).records()
        #expect(records.count == 20)
        #expect(await shop.requests.count == 20)
    }

    @Test func oneProductByHandle() async throws {
        let shop = FakeShopify([(200, Fixtures.productDetail)])
        let record = try await source(shop).product(handle: "gucci-jackie-1961-medium-tote")
        #expect(record?.handle == "gucci-jackie-1961-medium-tote")
        let body = try #require(await shop.bodies().first)
        #expect((body["query"] as? String)?.contains("query ProductDetail($handle: String!") == true)
        #expect((body["variables"] as? [String: Any])?["handle"] as? String == "gucci-jackie-1961-medium-tote")
    }

    @Test func theClosetAndItsRoomsTogetherAndNoRoomsWhenShopifyCantSay() async throws {
        // (The two requests go at once, so the stand-in answers by which query it's sent.)
        let catalog = try await StorefrontSource(
            endpoint: URL(string: "https://x.myshopify.com/api/2026-10/graphql.json"), token: "t",
            transport: { request in
                let body = String(data: request.httpBody ?? Data(), encoding: .utf8) ?? ""
                let ok = HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
                if body.contains("HomeRooms") {
                    let failed = HTTPURLResponse(url: request.url!, statusCode: 500, httpVersion: nil, headerFields: nil)!
                    return (Data(), failed)
                }
                return (Data(Fixtures.page(["a"], next: nil).utf8), ok)
            }
        ).catalog(roomCollections: Merch.homeRooms.map(\.collection))
        #expect(catalog.records.map(\.handle) == ["a"])
        #expect(catalog.roomLists.isEmpty)
    }

    @Test func noAddressOrTokenYetSaysSo() async {
        await #expect(throws: CatalogError.notConfigured) {
            _ = try await StorefrontSource(endpoint: nil, token: "").catalog(roomCollections: [])
        }
        await #expect(throws: CatalogError.notConfigured) {
            _ = try await StorefrontSource(endpoint: URL(string: "https://x.myshopify.com/api/2026-10/graphql.json"), token: "")
                .records()
        }
    }
}
