import Foundation

// The bag (APP-SPEC §3.7; the site's SPEC §11 and app/lib/bag/): a Shopify cart, read and changed through the
// Storefront API, or in the sample store a short list kept on the phone. Every piece is one of one: one line a piece,
// always one, no quantities. Ported from the site's bag.server.ts and types.ts with the same rules.

/// One piece in the bag (types.ts `BagLine`).
nonisolated struct BagLine: Hashable, Sendable, Identifiable {
    /// What removing it refers to (a Shopify cart line).
    var lineId: String
    var variantId: String
    var handle: String
    /// The size picked, for a piece that comes in several ("40R"); nil otherwise.
    var size: String?
    /// False once it has sold (it stays in the bag, saying so, until removed).
    var available: Bool
    var price: Double
    /// What the cart itself knows, for a piece that's no longer in the closet.
    var title: String
    var designer: String
    var image: PieceImage?

    var id: String { lineId }
}

/// The bag (types.ts `Bag`).
nonisolated struct BagContents: Hashable, Sendable {
    var lines: [BagLine]
    /// The pieces still for sale, added up.
    var subtotal: Double
    /// Shopify's checkout for this bag; nil in the sample store.
    var checkoutURL: URL?

    static let empty = BagContents(lines: [], subtotal: 0, checkoutURL: nil)

    /// The pieces in the bag still for sale: what the Bag tab's badge counts (types.ts `forSale`).
    var forSale: Int { lines.reduce(0) { $0 + ($1.available ? 1 : 0) } }
    /// Pieces in the bag, and every one has sold since it was added: nothing to check out (types.ts `allSold`).
    var allSold: Bool { !lines.isEmpty && forSale == 0 }

    func contains(variant: String) -> Bool { lines.contains { $0.variantId == variant } }

    init(lines: [BagLine], subtotal: Double? = nil, checkoutURL: URL?) {
        self.lines = lines
        self.subtotal = subtotal ?? lines.reduce(0) { $0 + ($1.available ? $1.price : 0) }
        self.checkoutURL = checkoutURL
    }
}

/// What came of adding or removing a piece (types.ts `BagResult`).
nonisolated enum BagResult: Equatable, Sendable {
    /// It worked; for an add, the piece now in the bag.
    case ok(added: AddedPiece?)
    /// It didn't, in a short, plain message ("That piece has just sold.").
    case failed(String)
}

nonisolated struct AddedPiece: Hashable, Sendable, Identifiable {
    var handle: String
    var variantId: String
    var id: String { variantId }
}

// MARK: - A cart as the bag's source

/// A cart as Shopify answers for it. `lines` is nil in a short answer (an id and a checkout link only), which is then
/// read back with a query (bag.server.ts: reading lines a short answer doesn't have is what crashed Add to Bag).
nonisolated struct CartAnswer: Sendable, Equatable {
    var id: String
    var checkoutURL: URL?
    var lines: [CartLineAnswer]?
}

/// One line of a cart: a size of a product (lines of anything else are left out).
nonisolated struct CartLineAnswer: Sendable, Equatable {
    var id: String
    var variantId: String
    var available: Bool
    var price: Double
    /// The size option's value, if the product has a size option.
    var size: String?
    var handle: String
    var title: String
    var vendor: String
    var image: PieceImage?
}

/// A mutation's answer: the cart as it is now, and what Shopify said went wrong.
nonisolated struct CartChange: Sendable, Equatable {
    var cart: CartAnswer?
    var problems: [String] = []
}

/// Where the bag's cart lives: Shopify's cart through the Storefront API, or the sample store's list on the phone.
nonisolated protocol CartService: Sendable {
    /// The cart, or nil when there's no such cart any more (Shopify forgets a cart within 30 days, and a completed
    /// one at once).
    func cart(id: String) async throws -> CartAnswer?
    /// Adds one of a size, starting a cart when there's none.
    func add(variantId: String, to cartId: String?) async throws -> CartChange
    func remove(lineId: String, from cartId: String) async throws -> CartChange
}

nonisolated enum BagRules {
    static let sold = "That piece has just sold."
    static let noAnswer = "The bag didn’t answer. Please try again."

    /// A cart as the bag (bag.server.ts `bagFromCart`). A cart with no lines to read counts as empty.
    static func bag(from cart: CartAnswer?) -> BagContents {
        guard let cart, let lines = cart.lines else { return .empty }
        return BagContents(
            lines: lines.map { l in
                BagLine(
                    lineId: l.id, variantId: l.variantId, handle: l.handle, size: l.size, available: l.available,
                    price: l.price, title: l.title, designer: l.vendor, image: l.image)
            },
            checkoutURL: cart.checkoutURL)
    }

    /// Adds a piece (bag.server.ts `changeCart`, intent add). Every piece is one of one: adding it again changes
    /// nothing. A piece Shopify won't add, or leaves out of the cart's answer, has just sold. Gives back the result,
    /// the cart's id (a new one when the add started a cart) and the bag as it is now, when it's known.
    static func add(
        variantId: String, cartId: String?, service: any CartService
    ) async -> (result: BagResult, cartId: String?, bag: BagContents?) {
        var cartId = cartId
        do {
            if let id = cartId {
                if let now = try await service.cart(id: id) {
                    let bag = bag(from: now)
                    if let there = bag.lines.first(where: { $0.variantId == variantId }) {
                        return (.ok(added: AddedPiece(handle: there.handle, variantId: there.variantId)), id, bag)
                    }
                } else {
                    // (Shopify no longer has that cart: the piece starts a new one.)
                    cartId = nil
                }
            }
            let change = try await service.add(variantId: variantId, to: cartId)
            guard change.problems.isEmpty, let cart = change.cart else { return (.failed(sold), cartId, nil) }
            // Shopify answers with the cart's lines; a short answer is read back with the new cart's id.
            let answered = cart.lines != nil ? cart : try await service.cart(id: cart.id)
            let now = bag(from: answered)
            guard let line = now.lines.first(where: { $0.variantId == variantId }) else {
                return (.failed(sold), cart.id, answered == nil ? nil : now)
            }
            return (.ok(added: AddedPiece(handle: line.handle, variantId: line.variantId)), cart.id, now)
        } catch {
            return (.failed(noAnswer), cartId, nil)
        }
    }

    /// Removes a piece (bag.server.ts, intent remove).
    static func remove(lineId: String, cartId: String, service: any CartService) async -> (result: BagResult, bag: BagContents?) {
        do {
            let change = try await service.remove(lineId: lineId, from: cartId)
            guard change.problems.isEmpty else { return (.failed(noAnswer), nil) }
            let answered = change.cart?.lines != nil ? change.cart : try await service.cart(id: cartId)
            return (.ok(added: nil), bag(from: answered))
        } catch {
            return (.failed(noAnswer), nil)
        }
    }
}

// MARK: - The sample store's bag

/// The sample store's bag: a short list on the phone (variant id and handle), read against the sample store's records
/// (bag.server.ts `sampleBag`). It has no checkout: Shopify's own checkout takes over on the real store.
nonisolated struct SampleCartService: CartService {
    /// The sample store's records, read once.
    let records: @Sendable () async -> [ProductRecord]
    let list: SampleBagList

    static let cartId = "sample"

    func cart(id: String) async throws -> CartAnswer? {
        await answer()
    }

    func add(variantId: String, to cartId: String?) async throws -> CartChange {
        let recs = await records()
        guard let rec = recs.first(where: { $0.variants.contains { $0.id == variantId && $0.available } }) else {
            return CartChange(cart: nil, problems: [BagRules.sold])
        }
        list.add(variantId: variantId, handle: rec.handle)
        return CartChange(cart: await answer())
    }

    func remove(lineId: String, from cartId: String) async throws -> CartChange {
        list.remove(variantId: lineId)
        return CartChange(cart: await answer())
    }

    private func answer() async -> CartAnswer {
        let recs = await records()
        let lines = list.items().map { item -> CartLineAnswer in
            let rec = recs.first { $0.handle == item.handle }
            let v = rec?.variants.first { $0.id == item.variantId }
            return CartLineAnswer(
                id: item.variantId, variantId: item.variantId, available: v?.available ?? false, price: v?.price ?? 0,
                size: (rec?.variants.count ?? 0) > 1 ? v?.size : nil, handle: item.handle,
                title: rec?.title ?? item.handle, vendor: rec?.vendor ?? "", image: rec?.images.first)
        }
        return CartAnswer(id: Self.cartId, checkoutURL: nil, lines: lines)
    }
}

/// The sample bag's list, kept on the phone (the site keeps it in the session).
nonisolated final class SampleBagList: @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String
    private let lock = NSLock()

    init(defaults: UserDefaults = .standard, key: String = "SOSSampleBag") {
        self.defaults = defaults
        self.key = key
    }

    func items() -> [(variantId: String, handle: String)] {
        lock.withLock {
            (defaults.array(forKey: key) as? [[String]] ?? []).compactMap { $0.count == 2 ? ($0[0], $0[1]) : nil }
        }
    }

    func add(variantId: String, handle: String) {
        lock.withLock {
            var list = defaults.array(forKey: key) as? [[String]] ?? []
            guard !list.contains(where: { $0.first == variantId }) else { return }
            list.append([variantId, handle])
            defaults.set(list, forKey: key)
        }
    }

    func remove(variantId: String) {
        lock.withLock {
            let list = (defaults.array(forKey: key) as? [[String]] ?? []).filter { $0.first != variantId }
            defaults.set(list, forKey: key)
        }
    }

    func replace(with items: [(variantId: String, handle: String)]) {
        lock.withLock { defaults.set(items.map { [$0.variantId, $0.handle] }, forKey: key) }
    }
}
