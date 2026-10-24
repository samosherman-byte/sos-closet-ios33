import SwiftUI

/// The tab row: SHOP ALL · WOMEN · MEN · JEWELRY · ART & HOME, all five across the width on any iPhone (the map is
/// always whole, SPEC §3), with one thin ink underline that follows the pager: under the finger during a swipe,
/// gliding with a tap, stretching a little in flight, and shrinking away toward Home, which has no tab.
struct TabRow: View {
    let width: CGFloat
    /// Where the pager is along the map (`PlacePager.position`).
    let position: CGFloat
    let onTap: (Place) -> Void

    @State private var frames: [Place: CGRect] = [:]

    var body: some View {
        let style: TextStyle = width < Layout.narrowWidth ? .tabNarrow : .tab
        HStack(spacing: 0) {
            ForEach(Place.tabs) { tab in
                Button { onTap(tab) } label: {
                    Text(tab.tabLabel(width: width))
                        .textStyle(style)
                        .foregroundStyle(.ink)
                        .fixedSize()
                        .frame(height: 44)
                        .contentShape(Rectangle())
                        .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(TabRow.space)) } action: { frames[tab] = $0 }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(tab.name)
                .accessibilityAddTraits(isCurrent(tab) ? .isSelected : [])
                if tab != Place.tabs.last { Spacer(minLength: 4) }
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 44)
        .coordinateSpace(.named(TabRow.space))
        .overlay(alignment: .topLeading) { underline(tracking: style.tracking * style.size) }
    }

    nonisolated private static let space = "tabRow"

    private func isCurrent(_ tab: Place) -> Bool {
        Int(position.rounded()) == tab.rawValue
    }

    /// 1pt of ink, 7pt above the row's lower hairline, as wide as the label (without its trailing letter spacing).
    @ViewBuilder private func underline(tracking: CGFloat) -> some View {
        let first = CGFloat(Place.tabs[0].rawValue), last = CGFloat(Place.tabs[Place.tabs.count - 1].rawValue)
        let clamped = min(max(position, first - 1), last)
        let lower = Place(rawValue: Int(clamped.rounded(.down))) ?? .home
        let upper = Place(rawValue: Int(clamped.rounded(.up))) ?? lower
        let t = clamped - CGFloat(lower.rawValue)
        if let to = frames[upper] {
            let from = frames[lower] ?? CGRect(x: to.midX, y: to.minY, width: 0, height: to.height) // Home: grows from the middle
            let minX = from.minX + (to.minX - from.minX) * t
            let rawWidth = (from.width + (to.width - from.width) * t) - tracking
            let stretch = 1 + 0.06 * sin(.pi * t) // to 106% wide mid-flight
            let width = max(0, rawWidth * stretch)
            Rectangle()
                .fill(.ink)
                .frame(width: width, height: 1)
                .offset(x: minX + (rawWidth - width) / 2, y: 36)
                .opacity(lower == .home ? Double(t) : 1)
                .accessibilityHidden(true)
        }
    }
}
