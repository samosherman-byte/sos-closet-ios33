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

/// A piece's page in a tab's stack (APP-SPEC §3.5, §3.6): the piece as its card had it (so the page shows it at once,
/// while the rest of its details load), the photo the card was showing (the page opens on it, SPEC §5), and the card
/// whose photo it zooms out of (nil: no card on screen, and the page pushes in).
struct PieceRoute: Hashable {
    var piece: Piece
    var photo = 0
    var zoomID: String?
}

/// The photo a piece's page is showing, for its card to turn to before the page zooms back into it (SPEC §5, "From
/// whichever photo the card shows").
struct TurnBack: Equatable {
    var zoomID: String
    var photo: Int
}

/// Where the shopper is: the tab bar's tab, the Shop page along the map, each tab's stack of pieces' pages, and the
/// bag's count for the Bag tab's badge.
@MainActor @Observable
final class AppState {
    var tab: AppTab = .home
    /// The pieces' pages opened over Home, and over Shop (each tab keeps its own, as iOS does).
    var homePath: [PieceRoute] = []
    var shopPath: [PieceRoute] = []
    /// The photo the piece's page on screen is showing (SPEC §5).
    var turnBack: TurnBack?
    private(set) var place: ShopPlace = .all
    /// Which way the last move along the map went (+1 rightward, −1 leftward), for the page's push.
    private(set) var direction = 1
    /// The pieces in the bag (the Bag tab's badge, hidden at zero). The bag itself comes with `bag/checkout`.
    var bagCount = 0
    /// The sizes added to the bag (their variant ids): a stand-in until `bag/checkout` makes the bag a Shopify cart.
    private(set) var bagVariants: [String] = []
    /// The scroll of the Shop page on screen. Each trip to a page starts a new one (a page opens at its top, or at the
    /// section it was opened at), so the page leaving keeps its own as it slides away.
    private(set) var shopScroll: PageScroll

    init() {
        shopScroll = Self.scroll(for: .all, landing: nil)
        #if DEBUG
        // For side-by-side screenshots with the app prototype, whose tab bar shows two pieces in the bag:
        // launch with `-SOSPreviewBagCount 2`. Debug builds only.
        // and `-SOSPreviewTab shop -SOSPreviewPlace women` opens on that page.
        let defaults = UserDefaults.standard
        bagCount = defaults.integer(forKey: "SOSPreviewBagCount")
        let places: [String: ShopPlace] = ["all": .all, "women": .women, "men": .men, "jewelry": .jewelry]
        if let place = defaults.string(forKey: "SOSPreviewPlace").flatMap({ places[$0] }) {
            self.place = place
            shopScroll = Self.scroll(for: place, landing: nil)
        }
        switch defaults.string(forKey: "SOSPreviewTab") {
        case "shop": tab = .shop
        case "saved": tab = .saved
        case "bag": tab = .bag
        default: break
        }
        #endif
    }

    /// Opens a piece's page over the page it was tapped on (Home or Shop), on the photo its card was showing, zooming
    /// out of that card's photo (`zoomID`) when there is one.
    func open(_ piece: Piece, photo: Int = 0, zoomID: String? = nil) {
        let route = PieceRoute(piece: piece, photo: photo, zoomID: zoomID)
        turnBack = nil
        if tab == .home {
            homePath.append(route)
        } else {
            tab = .shop
            shopPath.append(route)
        }
    }

    /// Adds a piece's size to the bag: every piece is one of one, so a size already in it adds nothing (SPEC §11).
    func addToBag(variant: String) {
        guard !bagVariants.contains(variant) else { return }
        bagVariants.append(variant)
        bagCount += 1
    }

    func inBag(_ variant: String) -> Bool { bagVariants.contains(variant) }

    /// Opens Shop at a place on the map, at its top or landing at a section (and a type in it): from Home it's always
    /// a move to the right (Home is left of everything). A link to a category in a small department's case opens the
    /// case at its top (phase 1: it narrows with a tag once Search exists, APP-SPEC §2).
    func open(_ next: ShopPlace, at section: String? = nil, type: String? = nil) {
        let from = tab == .shop ? place.rawValue : -1
        direction = next.rawValue >= from ? 1 : -1
        // (From a piece's page, its stack goes back to the Shop page as it goes there.)
        if !shopPath.isEmpty { shopPath = [] }
        shopScroll = Self.scroll(for: next, landing: section.map { ($0, type) })
        place = next
        tab = .shop
    }

    /// A new page's scroll: the tabs make way from 140pt down on a page with a tile row, 160pt elsewhere (SPEC §3).
    private static func scroll(for place: ShopPlace, landing: (section: String, type: String?)?) -> PageScroll {
        PageScroll(threshold: place == .all ? 160 : 140, landing: landing)
    }
}
