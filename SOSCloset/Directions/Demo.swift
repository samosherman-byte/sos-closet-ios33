import SwiftUI

/// TEMPORARY, for comparing the two navigation directions in the Simulator: launch arguments that open a direction
/// on a page, scrolled, so screenshots and recordings show the same moment every time. For example:
/// `xcrun simctl launch booted com.soscloset.app -SOSDirection A -SOSPage women -SOSScrollY 900 -SOSScrollUp 60`.
/// Without `-SOSDirection` the app opens on a chooser.
enum Demo {
    private static let defaults = UserDefaults.standard

    /// "A", "B" or "setup".
    static var direction: String? { defaults.string(forKey: "SOSDirection") }
    /// The page to open on: home, shopAll, women, men, jewelry, artHome.
    static var page: Place? {
        defaults.string(forKey: "SOSPage").flatMap { name in Place.allCases.first { "\($0)".lowercased() == name.lowercased() } }
    }
    /// Direction B's tab: home, shop, saved, bag.
    static var section: String? { defaults.string(forKey: "SOSSection") }
    static var scrollY: CGFloat { CGFloat(defaults.double(forKey: "SOSScrollY")) }
    /// The scroll edge effect under the header: hard, Apple's style for pinned rows of words (the site's white band
    /// is its web version), or the system's default soft one for comparison (`-SOSEdge soft`).
    static var edgeStyle: ScrollEdgeEffectStyle { defaults.string(forKey: "SOSEdge") == "soft" ? .soft : .hard }
    static var scrollUp: CGFloat { CGFloat(defaults.double(forKey: "SOSScrollUp")) }

    /// Scrolls the opening page down, then (with `-SOSScrollUp`) back up a little, as a finger would.
    static func scroll(_ place: Place, with position: Binding<ScrollPosition>) async {
        #if DEBUG
        guard place == (page ?? .shopAll), scrollY > 0 else { return }
        try? await Task.sleep(for: .seconds(1))
        withAnimation(.easeOut(duration: 0.6)) { position.wrappedValue.scrollTo(y: scrollY) }
        guard scrollUp > 0 else { return }
        try? await Task.sleep(for: .seconds(1.2))
        withAnimation(.easeOut(duration: 0.4)) { position.wrappedValue.scrollTo(y: scrollY - scrollUp) }
        #endif
    }
}

/// Opens the direction named at launch, or offers the choice (Debug builds; temporary until Sam picks).
struct DirectionsRoot: View {
    @State private var choice: String? = Demo.direction

    var body: some View {
        switch choice {
        case "A": DirectionA()
        case "B": DirectionB()
        case "setup": SetupCheckView()
        default: chooser
        }
    }

    private var chooser: some View {
        VStack(alignment: .leading, spacing: 28) {
            Text("Navigation").textStyle(.sectionLabel).foregroundStyle(.muted)
            option("A", title: "The site's header, natively", line: "Flat header and tab row at the top; Menu and Bag float in glass as you scroll.")
            option("B", title: "Native iOS tab bar", line: "Home, Shop, Saved and Bag in a glass bar at the bottom; departments at the top of Shop.")
            Spacer()
            Button("Setup check") { choice = "setup" }
                .textStyle(.cardSize).foregroundStyle(.muted)
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.paper)
    }

    private func option(_ key: String, title: String, line: String) -> some View {
        Button { choice = key } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text("\(key) · \(title)").textStyle(TextStyle(face: .body(.semibold), size: 17)).foregroundStyle(.ink)
                Text(line).textStyle(.cardName).foregroundStyle(.ink2).multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
