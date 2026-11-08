import Foundation
import Observation
import Security
import SwiftUI
@preconcurrency import ShopifyCheckoutSheetKit

/// The bag the app shows (APP-SPEC §3.7): its pieces, the sheet that opens when one is added, and Shopify's checkout.
///
/// On Sam's store the bag is a Storefront API cart whose id is kept in the iPhone's Keychain (Shopify treats the key
/// inside a cart id like a password), so it survives closing the app. When the app opens or comes back it reads the
/// cart again; a cart Shopify no longer has (carts expire within 30 days, and a completed one is deleted) starts a fresh,
/// empty bag. Nothing is held until checkout, and checkout never sells a piece twice. In the sample store the bag is a
/// short list on the phone and there's no checkout.
@MainActor @Observable final class Bag {
    private(set) var contents = BagContents.empty
    /// The size being added (its button says Adding…).
    private(set) var adding: String?
    /// Why a size couldn't be added, by its variant id ("That piece has just sold.").
    private(set) var problems: [String: String] = [:]
    /// The piece just added: the bag's sheet is open showing it.
    var sheet: AddedPiece?
    /// Shopify's checkout, open over the bag's sheet or the Bag tab.
    private(set) var checkout: CheckoutTrip?
    /// Something to say plainly about checkout, in the bag (it couldn't open, say).
    private(set) var notice: String?
    /// The order went through: the bag has started fresh, and closing checkout closes the bag's sheet too.
    private(set) var ordered = false

    struct CheckoutTrip: Equatable {
        var url: URL
        var over: Place
    }

    /// Where checkout was opened from, so closing it returns there.
    enum Place: Equatable {
        case sheet, page
    }

    let service: any CartService
    /// Shopify's checkout is there (Sam's store; not the sample store).
    let canCheckOut: Bool

    @ObservationIgnored private let keychain: CartKeychain?
    @ObservationIgnored private var cartId: String?
    @ObservationIgnored private var awaySince: Date?
    @ObservationIgnored private var previewPieces: [String]?
    @ObservationIgnored private var previewSheetShown = false

    /// The pieces still for sale: the Bag tab's badge (SPEC §11).
    var count: Int { contents.forSale }

    init(service: any CartService, canCheckOut: Bool, keychain: CartKeychain?, cartId: String? = nil) {
        self.service = service
        self.canCheckOut = canCheckOut
        self.keychain = keychain
        self.cartId = cartId ?? keychain?.read()
        #if DEBUG
        // For side-by-side screenshots with the app prototype, whose bag holds the Jackie and the orange Hermès
        // (`-SOSPreviewBagCount 2`, the first two; or `-SOSPreviewBag jackie,herm-orange`). Sample store only.
        let defaults = UserDefaults.standard
        if canCheckOut == false {
            if let ids = defaults.string(forKey: "SOSPreviewBag") {
                previewPieces = ids.split(separator: ",").map(String.init)
            } else if defaults.integer(forKey: "SOSPreviewBagCount") > 0 {
                previewPieces = Array(["jackie", "herm-orange"].prefix(defaults.integer(forKey: "SOSPreviewBagCount")))
            }
        }
        #endif
    }

    /// The bag of this build's store: Sam's store's cart, or the sample store's list.
    static func forThisBuild() -> Bag {
        switch StoreConfig.source {
        case .sample:
            let records = SampleRecords(folder: StoreConfig.sampleStoreURL)
            return Bag(
                service: SampleCartService(records: { await records.get() }, list: SampleBagList()), canCheckOut: false,
                keychain: nil, cartId: SampleCartService.cartId)
        case .shopify:
            return Bag(service: ShopifyCartService(client: StorefrontSource()), canCheckOut: true, keychain: CartKeychain())
        }
    }

    func contains(variant: String) -> Bool { contents.contains(variant: variant) }

    // MARK: Reading the cart

    /// Reads the cart again (when the app opens, comes back, and right before checkout). A cart Shopify no longer
    /// has starts a fresh, empty bag; one that can't be read just now keeps the bag as it was.
    func load() async {
        #if DEBUG
        if let ids = previewPieces, let list = (service as? SampleCartService)?.list {
            previewPieces = nil
            let records = await (service as! SampleCartService).records()
            list.replace(
                with: ids.compactMap { id in
                    guard let r = records.first(where: { $0.tags.contains("id:" + id) }),
                        let v = r.variants.first(where: \.available)
                    else { return nil }
                    return (v.id, r.handle)
                })
        }
        #endif
        guard let id = cartId else {
            contents = .empty
            return
        }
        do {
            if let cart = try await service.cart(id: id) {
                contents = BagRules.bag(from: cart)
            } else {
                forget()
            }
        } catch {
            // (Offline, or Shopify didn't answer: the bag stays as it was.)
        }
        #if DEBUG
        // `-SOSPreviewSheet 1` opens the bag's sheet on the last piece in it, as if it had just been added.
        if UserDefaults.standard.bool(forKey: "SOSPreviewSheet"), !previewSheetShown, let last = contents.lines.last {
            previewSheetShown = true
            sheet = AddedPiece(handle: last.handle, variantId: last.variantId)
        }
        #endif
    }

    /// Tell the bag when the app goes away and comes back: coming back reads the cart again.
    func scenePhaseChanged(to phase: ScenePhase) {
        switch phase {
        case .background:
            if awaySince == nil { awaySince = .now }
        case .active:
            if awaySince != nil {
                awaySince = nil
                Task { await load() }
            }
        default:
            break
        }
    }

    // MARK: Changing it

    /// Adds a size to the bag; it worked, the bag's sheet opens with the piece; it didn't, the problem is kept for the
    /// button's message.
    func add(variantId: String) async {
        guard adding == nil else { return }
        adding = variantId
        problems[variantId] = nil
        let (result, id, now) = await BagRules.add(variantId: variantId, cartId: cartId, service: service)
        if let id, id != cartId {
            cartId = id
            keychain?.save(id)
        }
        if let now { contents = now }
        adding = nil
        switch result {
        case .ok(let added):
            notice = nil
            sheet = added
            preload()
        case .failed(let message):
            problems[variantId] = message
            AccessibilityNotification.Announcement(message).post()
        }
    }

    /// Removes a piece: it slides out at once, and comes back if the cart couldn't change.
    func remove(_ line: BagLine, reduceMotion: Bool) async {
        guard let cartId else { return }
        let before = contents
        withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.easeOut(0.45)) {
            contents = BagContents(lines: contents.lines.filter { $0.lineId != line.lineId }, checkoutURL: contents.checkoutURL)
        }
        let (result, now) = await BagRules.remove(lineId: line.lineId, cartId: cartId, service: service)
        switch result {
        case .ok:
            if let now { contents = now }
            preload()
        case .failed(let message):
            withAnimation { contents = before }
            notice = message
        }
    }

    // MARK: Checkout

    /// Opens Shopify's checkout over the sheet or the Bag tab. Its address is read again right before it opens
    /// ("checkout URLs can go stale").
    func checkOut(from place: Place) async {
        guard canCheckOut else { return }
        notice = nil
        await load()
        guard let url = contents.checkoutURL, contents.forSale > 0 else { return }
        checkout = CheckoutTrip(url: url, over: place)
    }

    /// Checkout was closed (its close button, or swiped down): back to where it was opened. After an order, the bag's
    /// sheet goes too.
    func closeCheckout() {
        checkout = nil
        if ordered {
            ordered = false
            sheet = nil
        }
    }

    /// The order went through. Checkout says so before the buyer closes its thank-you page, and says it was closed
    /// after that too, so the bag starts fresh now, not on close.
    func completed() {
        forget()
        ordered = true
    }

    /// Checkout couldn't go on: say so plainly in the bag, and read the cart again (it may have expired).
    func checkoutFailed(_ error: CheckoutError) {
        checkout = nil
        switch error {
        case .configurationError(_, let code, _) where code == .storefrontPasswordRequired:
            notice = "Checkout can’t open while the store is behind its password page."
        case .checkoutExpired, .configurationError(_, .cartCompleted, _), .configurationError(_, .cartExpired, _):
            notice = "Checkout had closed. Please check out again."
        default:
            notice = "Checkout couldn’t open just now. Please try again."
        }
        Task { await load() }
    }

    /// Starts loading checkout so it opens quickly: when the bag opens, and after it changes.
    func preload() {
        guard canCheckOut, let url = contents.checkoutURL, contents.forSale > 0 else { return }
        ShopifyCheckoutSheetKit.preload(checkout: url)
    }

    private func forget() {
        if keychain != nil {
            cartId = nil
            keychain?.delete()
        }
        contents = .empty
    }
}

/// The cart's id in the iPhone's Keychain: Shopify treats the key inside a cart id like a password.
nonisolated struct CartKeychain: Sendable {
    var service = "com.soscloset.bag"
    var account = "cart"

    private var query: [CFString: Any] {
        [kSecClass: kSecClassGenericPassword, kSecAttrService: service, kSecAttrAccount: account]
    }

    func read() -> String? {
        var q = query
        q[kSecReturnData] = true
        q[kSecMatchLimit] = kSecMatchLimitOne
        var out: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func save(_ id: String) {
        delete()
        var q = query
        q[kSecValueData] = Data(id.utf8)
        q[kSecAttrAccessible] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        SecItemAdd(q as CFDictionary, nil)
    }

    func delete() {
        SecItemDelete(query as CFDictionary)
    }
}

/// The sample store's records, read once, for the sample bag.
actor SampleRecords {
    private let folder: URL?
    private var cached: [ProductRecord]?

    init(folder: URL?) {
        self.folder = folder
    }

    func get() -> [ProductRecord] {
        if let cached { return cached }
        let records = folder.flatMap { try? SampleStoreSource(folder: $0).read().records } ?? []
        cached = records
        return records
    }
}
