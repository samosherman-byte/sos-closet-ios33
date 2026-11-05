import SwiftUI

/// A page under the site's header (APP-SPEC §7): the scrolling page, with the header in its `safeAreaBar` so the
/// system's scroll edge effect sits behind it once the page scrolls under, and the header following the scroll.
struct HeaderPage<Content: View>: View {
    /// The page's tab on the map (nil on Home, where no tab is underlined).
    var current: ShopPlace?
    /// Home and Shop show the tab row; Saved and the bag show the top row alone.
    var showsMap = true
    /// Pull to refresh fetches the closet again (APP-SPEC §3.1).
    var refresh: (@MainActor @Sendable () async -> Void)? = nil
    @ViewBuilder var content: (_ width: CGFloat) -> Content

    @Environment(AppState.self) private var app
    @State private var scroll = HeaderScroll()
    @State private var scrolled = false
    @State private var position = ScrollPosition(edge: .top)

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ScrollView {
                content(width)
                    .frame(width: width)
            }
            .scrollIndicators(.hidden)
            .scrollPosition($position)
            .refreshable(enabled: refresh != nil) { await refresh?() }
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
        #if DEBUG
        .task {
            // For side-by-side screenshots with the prototype's still moments: `-SOSPreviewScroll 560` opens the page
            // scrolled that far down (the header as if scrolling down). Debug builds only.
            let y = UserDefaults.standard.double(forKey: "SOSPreviewScroll")
            guard y > 0 else { return }
            try? await Task.sleep(for: .milliseconds(600))
            position.scrollTo(y: y)
        }
        #endif
    }
}

private extension View {
    /// Pull to refresh only where the page has something to refresh.
    @ViewBuilder func refreshable(enabled: Bool, action: @escaping @Sendable () async -> Void) -> some View {
        if enabled { refreshable(action: action) } else { self }
    }
}
