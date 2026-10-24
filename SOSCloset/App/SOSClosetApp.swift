import SwiftUI
@preconcurrency import ShopifyCheckoutSheetKit

@main
struct SOSClosetApp: App {
    init() {
        // Shopify's own checkout, with the store's checkout branding (its "web" look, light only; APP-SPEC §3.7, §8).
        ShopifyCheckoutSheetKit.configure {
            $0.colorScheme = .web
        }
    }

    var body: some Scene {
        WindowGroup {
            DirectionsRoot()
        }
    }
}
