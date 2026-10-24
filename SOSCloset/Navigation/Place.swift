import SwiftUI

/// The tab map (SPEC §1.1, §2): every page has a position, and every move between them goes in that direction.
/// Home sits left of everything, then Shop All and the four departments.
nonisolated enum Place: Int, CaseIterable, Hashable, Identifiable, Sendable {
    case home = -1, shopAll, women, men, jewelry, artHome

    var id: Int { rawValue }

    /// The places the tab row shows (Home is reached from the logo).
    static let tabs: [Place] = [.shopAll, .women, .men, .jewelry, .artHome]
    static let departments: [Place] = [.women, .men, .jewelry, .artHome]

    /// The department's key in Shopify's `dept:` tags (Art & Home stayed `home`, so tags don't change).
    var deptKey: String? {
        switch self {
        case .women: "women"
        case .men: "men"
        case .jewelry: "jewelry"
        case .artHome: "home"
        case .home, .shopAll: nil
        }
    }

    init?(deptKey: String) {
        guard let place = Place.departments.first(where: { $0.deptKey == deptKey }) else { return nil }
        self = place
    }

    var name: String {
        switch self {
        case .home: "SOS Closet"
        case .shopAll: "Shop All"
        case .women: "Women"
        case .men: "Men"
        case .jewelry: "Jewelry & Watches"
        case .artHome: "Art & Home"
        }
    }

    /// The tab's label on phones (SPEC §3): JEWELRY and ART & HOME, just ART under 375pt wide.
    func tabLabel(width: CGFloat) -> String {
        switch self {
        case .jewelry: "Jewelry"
        case .artHome: width < Layout.narrowWidth ? "Art" : "Art & Home"
        default: name
        }
    }
}
