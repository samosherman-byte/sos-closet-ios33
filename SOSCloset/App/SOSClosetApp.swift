import SwiftUI
import UIKit
@preconcurrency import ShopifyCheckoutSheetKit

@main
struct SOSClosetApp: App {
    init() {
        // Shopify's own checkout, with the store's checkout branding (its "web" look, light only; APP-SPEC §3.7, §8).
        ShopifyCheckoutSheetKit.configure {
            $0.colorScheme = .web
        }
        // The bag's count on the Bag tab is a small black badge, as on the site (APP-SPEC §3.7), not the system's red.
        // Only the badge's color is set; the bar itself stays the system's Liquid Glass.
        let tabBar = UITabBarAppearance()
        for item in [tabBar.stackedLayoutAppearance, tabBar.inlineLayoutAppearance, tabBar.compactInlineLayoutAppearance] {
            item.normal.badgeBackgroundColor = UIColor(Color.ink)
            item.selected.badgeBackgroundColor = UIColor(Color.ink)
        }
        UITabBar.appearance().standardAppearance = tabBar
        UITabBar.appearance().scrollEdgeAppearance = tabBar
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
