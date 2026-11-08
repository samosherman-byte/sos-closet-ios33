import Foundation
import Testing
@testable import SOSCloset

// The bag (APP-SPEC §3.7), against a stand-in for Shopify's cart: the same cases as the site's
// app/lib/bag/bag.test.ts. Shopify answers a mutation with the cart's lines when the app asks for them (`lines: true`
// here); an answer without them is a short cart (an id and a checkout link), and the lines are then read with a query.

private nonisolated let variant = "gid://shopify/ProductVariant/1"

private nonisolated func line(_ variantId: String, available: Bool = true) -> CartLineAnswer {
    CartLineAnswer(
        id: "line-\(variantId)", variantId: variantId, available: available, price: 2600, size: nil,
        handle: "gucci-jackie", title: "Jackie 1961", vendor: "Gucci", image: nil)
}

/// A fake cart: no cart until the first add, then one cart holding what was added.
private actor FakeCart: CartService {
    let stocked: Bool
    let failing: Bool
    let withLines: Bool
    private(set) var lines: [CartLineAnswer] = []
    private(set) var exists = false
    private(set) var reads: [String] = []
    private(set) var adds = 0

    init(stocked: Bool = true, failing: Bool = false, lines: Bool = false) {
        self.stocked = stocked
        self.failing = failing
        self.withLines = lines
    }

    static let id = "gid://shopify/Cart/c1"
    private var full: CartAnswer { CartAnswer(id: Self.id, checkoutURL: URL(string: "https://store.example/checkout"), lines: lines) }
    private var short: CartAnswer { CartAnswer(id: Self.id, checkoutURL: URL(string: "https://store.example/checkout"), lines: withLines ? lines : nil) }

    func cart(id: String) async throws -> CartAnswer? {
        if failing { throw CatalogError.server(status: 503) }
        reads.append(id)
        return exists && id == Self.id ? full : nil
    }

    func add(variantId: String, to cartId: String?) async throws -> CartChange {
        if failing { throw CatalogError.server(status: 503) }
        adds += 1
        exists = true
        if stocked { lines.append(line(variantId)) }
        return CartChange(cart: short)
    }

    func remove(lineId: String, from cartId: String) async throws -> CartChange {
        lines.removeAll { $0.id == lineId }
        return CartChange(cart: short)
    }

    /// Shopify has forgotten the cart (it expired, or its order completed).
    func forget() { exists = false; lines = [] }
}

@Suite("The bag on the real store")
struct BagTests {
    @Test func addsAPieceInOneTripWhenShopifyAnswersWithTheLines() async {
        let cart = FakeCart(lines: true)
        let (result, id, bag) = await BagRules.add(variantId: variant, cartId: nil, service: cart)
        #expect(result == .ok(added: AddedPiece(handle: "gucci-jackie", variantId: variant)))
        // The add started the cart: its id is kept.
        #expect(id == FakeCart.id)
        #expect(bag?.lines.map(\.variantId) == [variant])
        // With no cart yet, nothing to check first, and nothing read back after adding.
        #expect(await cart.reads.isEmpty)
    }

    @Test func saysSoWhenThePieceHasJustSoldFromShopifysAnswer() async {
        let cart = FakeCart(stocked: false, lines: true)
        let (result, _, _) = await BagRules.add(variantId: variant, cartId: nil, service: cart)
        #expect(result == .failed("That piece has just sold."))
        #expect(await cart.reads.isEmpty)
    }

    @Test func addsAPieceFromAShortAnswerTooReadingTheLinesBack() async {
        let cart = FakeCart()
        let (result, id, bag) = await BagRules.add(variantId: variant, cartId: nil, service: cart)
        #expect(result == .ok(added: AddedPiece(handle: "gucci-jackie", variantId: variant)))
        #expect(id == FakeCart.id)
        #expect(bag?.lines.count == 1)
        // The lines came from a query with the new cart's id, not from the mutation's short answer.
        #expect(await cart.reads == [FakeCart.id])
    }

    @Test func addingTheSamePieceAgainChangesNothingAndRemovingItWorks() async {
        let cart = FakeCart()
        let (_, id, _) = await BagRules.add(variantId: variant, cartId: nil, service: cart)
        let again = await BagRules.add(variantId: variant, cartId: id, service: cart)
        #expect(again.result == .ok(added: AddedPiece(handle: "gucci-jackie", variantId: variant)))
        #expect(await cart.adds == 1)
        let gone = await BagRules.remove(lineId: "line-\(variant)", cartId: id!, service: cart)
        #expect(gone.result == .ok(added: nil))
        #expect(gone.bag?.lines.isEmpty == true)
        #expect(await cart.lines.isEmpty)
    }

    @Test func saysSoWhenThePieceHasJustSold() async {
        let (result, _, _) = await BagRules.add(variantId: variant, cartId: nil, service: FakeCart(stocked: false))
        #expect(result == .failed("That piece has just sold."))
    }

    @Test func aCartShopifyNoLongerHasStartsANewOne() async {
        let cart = FakeCart(lines: true)
        let (_, id, _) = await BagRules.add(variantId: "a", cartId: nil, service: cart)
        await cart.forget()
        let (result, newId, bag) = await BagRules.add(variantId: variant, cartId: id, service: cart)
        #expect(result == .ok(added: AddedPiece(handle: "gucci-jackie", variantId: variant)))
        #expect(newId == FakeCart.id)
        #expect(bag?.lines.map(\.variantId) == [variant])
    }

    @Test func answersWithAMessageNotAnErrorWhenTheAPIDoesNotAnswer() async {
        let (result, _, _) = await BagRules.add(variantId: variant, cartId: nil, service: FakeCart(failing: true))
        guard case .failed(let message) = result else {
            Issue.record("expected a message")
            return
        }
        #expect(message.localizedCaseInsensitiveContains("try again"))
    }

    @Test func readsAnEmptyBagFromACartWithNothingToRead() {
        #expect(BagRules.bag(from: nil) == .empty)
        // A mutation's short answer.
        #expect(BagRules.bag(from: CartAnswer(id: "x", checkoutURL: nil, lines: nil)) == .empty)
    }

    @Test func countsOnlyThePiecesStillForSaleAndKnowsWhenEveryOneHasSold() {
        func bag(_ ls: CartLineAnswer...) -> BagContents {
            BagRules.bag(from: CartAnswer(id: "c", checkoutURL: URL(string: "u"), lines: ls))
        }
        let some = bag(line("a"), line("b", available: false))
        #expect(some.forSale == 1)
        #expect(!some.allSold)
        let gone = bag(line("a", available: false), line("b", available: false))
        #expect(gone.forSale == 0)
        #expect(gone.allSold)
        // An empty bag hasn't "all sold": it's empty.
        #expect(!BagContents.empty.allSold)
    }

    @Test func sumsOnlyThePiecesStillForSale() {
        let bag = BagRules.bag(
            from: CartAnswer(id: "c", checkoutURL: URL(string: "u"), lines: [line("a"), line("b", available: false)]))
        #expect(bag.lines.map(\.available) == [true, false])
        #expect(bag.subtotal == 2600)
        #expect(bag.checkoutURL == URL(string: "u"))
    }
}

@Suite("Shopify's cart, as the app reads and changes it")
struct CartAPITests {
    @Test func aCartAnswerAsTheBagReadsIt() throws {
        let json = """
            {"data":{"cart":{"id":"gid://shopify/Cart/c1?key=secret","checkoutUrl":"https://store.example/cart/c/c1",
            "totalQuantity":2,"lines":{"nodes":[
              {"id":"line-1","quantity":1,"merchandise":{"id":"gid://shopify/ProductVariant/1","availableForSale":true,
                "price":{"amount":"2600.0"},"image":{"url":"https://cdn.shopify.com/a.jpg","altText":null,"width":1200,"height":1500},
                "selectedOptions":[{"name":"Title","value":"Default Title"}],
                "product":{"handle":"gucci-jackie","title":"Jackie 1961 Medium Tote","vendor":"Gucci"}}},
              {"id":"line-2","quantity":1,"merchandise":{"id":"gid://shopify/ProductVariant/2","availableForSale":false,
                "price":{"amount":"1200.0"},"image":null,
                "selectedOptions":[{"name":"Size","value":"42R"}],
                "product":{"handle":"coppley-suit","title":"Custom Windowpane Suit","vendor":"Coppley"}}},
              {"id":"line-3","quantity":1,"merchandise":{}}
            ]}}}}
            """
        let data: CartAPI.CartData = try StorefrontSource.decode(Data(json.utf8), response: nil)
        let bag = BagRules.bag(from: data.cart.map(CartAPI.answer))
        // (A line that isn't a size of a product is left out.)
        #expect(bag.lines.map(\.variantId) == ["gid://shopify/ProductVariant/1", "gid://shopify/ProductVariant/2"])
        #expect(bag.lines[0].size == nil)
        #expect(bag.lines[1].size == "42R")
        #expect(bag.lines[0].image?.alt == "Jackie 1961 Medium Tote")
        #expect(bag.lines[0].designer == "Gucci")
        #expect(bag.subtotal == 2600)
        #expect(bag.forSale == 1)
        #expect(bag.checkoutURL?.absoluteString == "https://store.example/cart/c/c1")
    }

    @Test func aMutationsProblemsAreKept() throws {
        let json = """
            {"data":{"cartLinesAdd":{"cart":null,"userErrors":[{"field":["lines"],"message":"The merchandise is out of stock."}],"warnings":[]}}}
            """
        let data: CartAPI.AddData = try StorefrontSource.decode(Data(json.utf8), response: nil)
        let change = CartAPI.change(data.cartLinesAdd)
        #expect(change.cart == nil)
        #expect(change.problems == ["The merchandise is out of stock."])
    }

    @Test func addingSendsOneOfTheSize() throws {
        let source = StorefrontSource(endpoint: URL(string: "https://store.example/api/2026-10/graphql.json"), token: "t")
        let request = try source.request(
            CartQueries.add,
            variables: [
                "cartId": .string("c1"),
                "lines": .list([.object(["merchandiseId": .string(variant), "quantity": .int(1)])]),
            ])
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        let vars = body["variables"] as! [String: Any]
        let lines = vars["lines"] as! [[String: Any]]
        #expect(lines.count == 1)
        #expect(lines[0]["merchandiseId"] as? String == variant)
        #expect(lines[0]["quantity"] as? Int == 1)
        #expect(vars["country"] as? String == "US")
        #expect((body["query"] as! String).contains("cartLinesAdd(cartId: $cartId, lines: $lines)"))
    }
}

@Suite("The sample store's bag")
struct SampleBagTests {
    private func service() -> SampleCartService {
        let defaults = UserDefaults(suiteName: "SOSSampleBagTests-\(UUID().uuidString)")!
        return SampleCartService(records: { SampleFiles.records }, list: SampleBagList(defaults: defaults))
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func aShortListOnThePhoneWithNoCheckout() async {
        let cart = service()
        let jackie = SampleFiles.record("gucci-jackie-1961-medium-tote")
        let v = jackie.variants.first { $0.available }!.id
        let (result, id, bag) = await BagRules.add(variantId: v, cartId: SampleCartService.cartId, service: cart)
        #expect(result == .ok(added: AddedPiece(handle: jackie.handle, variantId: v)))
        #expect(id == SampleCartService.cartId)
        #expect(bag?.lines.map(\.handle) == [jackie.handle])
        #expect(bag?.lines.first?.price == jackie.variants.first?.price)
        #expect(bag?.checkoutURL == nil)
        // One of one: again, nothing changes.
        _ = await BagRules.add(variantId: v, cartId: id, service: cart)
        #expect(BagRules.bag(from: try? await cart.cart(id: SampleCartService.cartId)).lines.count == 1)
        let gone = await BagRules.remove(lineId: v, cartId: SampleCartService.cartId, service: cart)
        #expect(gone.bag?.lines.isEmpty == true)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func aSizeTheStoreHasNoneOfHasJustSold() async {
        let (result, _, _) = await BagRules.add(variantId: "sample:nothing", cartId: SampleCartService.cartId, service: service())
        #expect(result == .failed("That piece has just sold."))
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func aPieceInSeveralSizesKeepsTheSizePicked() async {
        let cart = service()
        let suit = SampleFiles.record("coppley-custom-windowpane-suit-light-beige")
        let v = suit.variants.first { $0.available && $0.size == "42R" }!
        let (_, _, bag) = await BagRules.add(variantId: v.id, cartId: SampleCartService.cartId, service: cart)
        #expect(bag?.lines.first?.size == "42R")
    }
}
