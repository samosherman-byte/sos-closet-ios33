import SwiftUI

/// The tab bar's places (APP-SPEC §7): Home, Shop, Saved and Bag. Search joins them as its own round button in phase 2.
enum AppTab: Hashable {
    case home, shop, saved, bag
}

/// The tab row is a map (SPEC §1.1, §2): Shop All (0), Women (1), Men (2), Jewelry & Objects (3), with Home at −1, left
/// of everything. Every move between them goes in the map's direction.
enum ShopPlace: Int, CaseIterable, Identifiable, Hashable {
    case all, women, men, jewelry

    var id: Int { rawValue }

    /// The tab's words. Under 375pt wide Jewelry & Objects shortens to Jewelry, where the full name would overflow (SPEC §3).
    func label(narrow: Bool) -> String {
        switch self {
        case .all: "Shop All"
        case .women: "Women"
        case .men: "Men"
        case .jewelry: narrow ? "Jewelry" : "Jewelry & Objects"
        }
    }
}

/// Where the shopper is: the tab bar's tab, the Shop page along the map, and the bag's count for the Bag tab's badge.
@MainActor @Observable
final class AppState {
    var tab: AppTab = .home
    private(set) var place: ShopPlace = .all
    /// Which way the last move along the map went (+1 rightward, −1 leftward), for the page's push.
    private(set) var direction = 1
    /// The pieces in the bag (the Bag tab's badge, hidden at zero). The bag itself comes with `bag/checkout`.
    var bagCount = 0

    init() {
        #if DEBUG
        // For side-by-side screenshots with the app prototype, whose tab bar shows two pieces in the bag:
        // launch with `-SOSPreviewBagCount 2`. Debug builds only.
        // and `-SOSPreviewTab shop -SOSPreviewPlace women` opens on that page.
        let defaults = UserDefaults.standard
        bagCount = defaults.integer(forKey: "SOSPreviewBagCount")
        let places: [String: ShopPlace] = ["all": .all, "women": .women, "men": .men, "jewelry": .jewelry]
        if let place = defaults.string(forKey: "SOSPreviewPlace").flatMap({ places[$0] }) { self.place = place }
        switch defaults.string(forKey: "SOSPreviewTab") {
        case "shop": tab = .shop
        case "saved": tab = .saved
        case "bag": tab = .bag
        default: break
        }
        #endif
    }

    /// Opens Shop at a place on the map: from Home it's always a move to the right (Home is left of everything).
    func open(_ next: ShopPlace) {
        let from = tab == .shop ? place.rawValue : -1
        direction = next.rawValue >= from ? 1 : -1
        place = next
        tab = .shop
    }
}
