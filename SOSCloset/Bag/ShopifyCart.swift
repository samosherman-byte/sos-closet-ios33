import Foundation

// The bag on Sam's store: a Storefront API cart (APP-SPEC §3.7; docs/platform-notes.md, "Storefront API"), with the
// fields the site's cart reads (app/lib/fragments.ts) and the same mutations Hydrogen's cart handler sends. Each piece
// is one line of one.

nonisolated enum CartQueries {
    static let cartFields = """
        fragment BagCart on Cart {
          id
          checkoutUrl
          totalQuantity
          lines(first: 100) {
            nodes {
              id
              quantity
              merchandise {
                ... on ProductVariant {
                  id
                  availableForSale
                  price {
                    amount
                  }
                  image {
                    url
                    altText
                    width
                    height
                  }
                  selectedOptions {
                    name
                    value
                  }
                  product {
                    handle
                    title
                    vendor
                  }
                }
              }
            }
          }
        }
        """

    private static let payload = """
        cart {
          ...BagCart
        }
        userErrors {
          field
          message
        }
        warnings {
          code
          message
        }
        """

    static let cart = """
        query BagCartQuery($id: ID!, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          cart(id: $id) {
            ...BagCart
          }
        }
        \(cartFields)
        """

    static let create = """
        mutation BagCartCreate($lines: [CartLineInput!]!, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          cartCreate(input: { lines: $lines }) {
            \(payload)
          }
        }
        \(cartFields)
        """

    static let add = """
        mutation BagLinesAdd($cartId: ID!, $lines: [CartLineInput!]!, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          cartLinesAdd(cartId: $cartId, lines: $lines) {
            \(payload)
          }
        }
        \(cartFields)
        """

    static let remove = """
        mutation BagLinesRemove($cartId: ID!, $lineIds: [ID!]!, $country: CountryCode, $language: LanguageCode)
        @inContext(country: $country, language: $language) {
          cartLinesRemove(cartId: $cartId, lineIds: $lineIds) {
            \(payload)
          }
        }
        \(cartFields)
        """
}

/// Shopify's cart, as the queries above ask for it.
nonisolated enum CartAPI {
    nonisolated struct Cart: Decodable, Sendable {
        var id: String
        var checkoutUrl: String?
        var lines: StorefrontAPI.Nodes<Line>?
    }

    nonisolated struct Line: Decodable, Sendable {
        var id: String
        var merchandise: Merchandise?
    }

    /// A size of a product (anything else a cart line can hold has no product, and is left out).
    nonisolated struct Merchandise: Decodable, Sendable {
        var id: String?
        var availableForSale: Bool?
        var price: StorefrontAPI.Money?
        var image: StorefrontAPI.Image?
        var selectedOptions: [StorefrontAPI.Option]?
        var product: Product?
    }

    nonisolated struct Product: Decodable, Sendable {
        var handle: String
        var title: String
        var vendor: String
    }

    nonisolated struct UserError: Decodable, Sendable {
        var message: String
    }

    nonisolated struct Payload: Decodable, Sendable {
        var cart: Cart?
        var userErrors: [UserError]?
    }

    nonisolated struct CartData: Decodable, Sendable { var cart: Cart? }
    nonisolated struct CreateData: Decodable, Sendable { var cartCreate: Payload? }
    nonisolated struct AddData: Decodable, Sendable { var cartLinesAdd: Payload? }
    nonisolated struct RemoveData: Decodable, Sendable { var cartLinesRemove: Payload? }

    static func answer(_ cart: Cart) -> CartAnswer {
        CartAnswer(
            id: cart.id,
            checkoutURL: cart.checkoutUrl.flatMap(URL.init(string:)),
            lines: cart.lines.map { lines in
                lines.nodes.compactMap { l -> CartLineAnswer? in
                    guard let m = l.merchandise, let id = m.id, let product = m.product else { return nil }
                    return CartLineAnswer(
                        id: l.id, variantId: id, available: m.availableForSale ?? false, price: m.price?.amount ?? 0,
                        size: m.selectedOptions?.first { $0.name.lowercased() == "size" }?.value,
                        handle: product.handle, title: product.title, vendor: product.vendor,
                        image: m.image.flatMap(StorefrontMapping.image).map { image in
                            var i = image
                            if i.alt.isEmpty { i.alt = product.title }
                            return i
                        })
                }
            })
    }

    static func change(_ payload: Payload?) -> CartChange {
        CartChange(cart: payload?.cart.map(answer), problems: payload?.userErrors?.map(\.message) ?? [])
    }
}

/// The bag on Sam's store, through the same Storefront API client as the closet.
nonisolated struct ShopifyCartService: CartService {
    var client: StorefrontSource

    func cart(id: String) async throws -> CartAnswer? {
        let data: CartAPI.CartData = try await client.query(CartQueries.cart, variables: ["id": .string(id)])
        return data.cart.map(CartAPI.answer)
    }

    func add(variantId: String, to cartId: String?) async throws -> CartChange {
        let lines: StorefrontSource.Variable = .list([.object(["merchandiseId": .string(variantId), "quantity": .int(1)])])
        if let cartId {
            let data: CartAPI.AddData = try await client.query(
                CartQueries.add, variables: ["cartId": .string(cartId), "lines": lines])
            return CartAPI.change(data.cartLinesAdd)
        }
        let data: CartAPI.CreateData = try await client.query(CartQueries.create, variables: ["lines": lines])
        return CartAPI.change(data.cartCreate)
    }

    func remove(lineId: String, from cartId: String) async throws -> CartChange {
        let data: CartAPI.RemoveData = try await client.query(
            CartQueries.remove, variables: ["cartId": .string(cartId), "lineIds": .list([.string(lineId)])])
        return CartAPI.change(data.cartLinesRemove)
    }
}
