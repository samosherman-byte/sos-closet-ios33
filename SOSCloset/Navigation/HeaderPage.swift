import SwiftUI

/// A page under the site's header (APP-SPEC §7): the scrolling page, with the header in its `safeAreaBar` so the
/// system's scroll edge effect sits behind it once the page scrolls under, and the header following the scroll.
struct HeaderPage<Content: View>: View {
    /// The page's tab on the map (nil on Home, where no tab is underlined).
    var current: ShopPlace?
    /// Home and Shop show the tab row; Saved and the bag show the top row alone.
    var showsMap = true
    @ViewBuilder var content: (_ width: CGFloat) -> Content

    @Environment(AppState.self) private var app
    @State private var scroll = HeaderScroll()
    @State private var scrolled = false

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ScrollView {
                content(width)
                    .frame(width: width)
            }
            .scrollIndicators(.hidden)
            .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y + $0.contentInsets.top } action: { _, y in
                scroll.update(offset: y)
                scrolled = y > 6
            }
            .safeAreaBar(edge: .top, spacing: 0) {
                SiteHeader(
                    current: current,
                    tabsShown: showsMap ? scroll.tabsShown : !scrolled,
                    width: width,
                    showsMap: showsMap,
                    onMenu: {},
                    onPick: { app.open($0) }
                )
            }
        }
        .background(.paper)
        .toolbar(.hidden, for: .navigationBar)
    }
}
