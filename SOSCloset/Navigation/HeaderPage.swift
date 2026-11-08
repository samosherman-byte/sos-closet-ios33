import SwiftUI

/// A page under the site's header (APP-SPEC §7): the page's own scroll view(s), with the header in a `safeAreaBar` so
/// the system's scroll edge effect sits behind it once the page scrolls under, the header following the page's scroll,
/// and the directory over it all when it's open (SPEC §4). Shop's pages push in and out under the same header.
struct PageFrame<Content: View>: View {
    /// The page's tab on the map (nil on Home, where no tab is underlined, and on Saved and the bag).
    var current: ShopPlace?
    /// Home and Shop show the tab row; Saved and the bag show the top row alone.
    var showsMap = true
    /// The scroll of the page on screen, which the header follows.
    let scroll: PageScroll
    /// A Shop page: the place line's department (the section and type come from the scroll).
    var placeName: String? = nil
    /// No category in the place line (a small department's case has no headings).
    var placeHasSections = true
    /// A page with a tile row: its compact copy, for the way back up.
    var compact: CompactTiles? = nil
    /// A piece's page: its Back and place line in the tab row's place (SPEC §10).
    var piece: PieceTop? = nil
    @ViewBuilder var content: (_ width: CGFloat) -> Content

    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.openURL) private var openURL
    @State private var directory = DirectoryState()

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            content(width)
                .frame(width: width)
                .scrollDisabled(directory.isOpen)
                .safeAreaBar(edge: .top, spacing: 0) {
                    // (VoiceOver reads the header first, top row then the row under it, then the page.)
                    header(.bar, width: width)
                        .accessibilitySortPriority(3)
                }
                .overlay(alignment: .top) {
                    header(.tabs, width: width)
                        .padding(.top, SiteHeader.rowHeight)
                        .accessibilitySortPriority(2)
                }
                .overlay(alignment: .top) {
                    let insets = geometry.safeAreaInsets
                    let screen = geometry.size.height + insets.top + insets.bottom
                    DirectoryLayer(
                        state: directory, page: current ?? piece?.place, section: piece?.section ?? scroll.section,
                        type: piece == nil ? scroll.type : "",
                        maxHeight: screen - max(120, 0.16 * screen) - (insets.top + SiteHeader.rowHeight + 4),
                        choose: choose
                    )
                    .padding(.top, SiteHeader.rowHeight)
                }
        }
        .background(.paper)
        .toolbar(.hidden, for: .navigationBar)
        #if DEBUG
        .task { await openPreviewDirectory() }
        #endif
    }

    private func header(_ part: SiteHeader.Part, width: CGFloat) -> some View {
        SiteHeader(
            part: part,
            current: current,
            mode: scroll.mode,
            scrolled: scroll.scrolled,
            width: width,
            showsMap: showsMap,
            place: placeName.map {
                PlaceWords(
                    dept: $0, section: placeHasSections ? scroll.section : "", type: placeHasSections ? scroll.type : "")
            },
            rollFrom: scroll.rollFrom,
            compact: compact,
            compactCurrent: scroll.section,
            piece: piece,
            directoryOpen: directory.isOpen,
            onMenu: { directory.isOpen ? directory.close() : directory.open(fromLine: false) },
            onPlace: { directory.open(fromLine: true) },
            onPick: pickTab
        )
    }

    /// A tab: the page's own glides back to the top (SPEC §7: no ALL on a department's row); another pushes in from
    /// its side of the map.
    private func pickTab(_ place: ShopPlace) {
        if place == current {
            scroll.glideToTop(reduceMotion: reduceMotion)
        } else {
            app.open(place)
        }
    }

    /// Going somewhere from the directory (SPEC §4): in the department you're in it's the table of contents, gliding to
    /// a heading (or the top); another department pushes in from its side of the map and lands there. The house links
    /// close it and go.
    private func choose(_ choice: DirectoryChoice) {
        directory.close()
        switch choice {
        case .place(let place, let section, let type):
            // (From a piece's page every place is a trip: it goes back to Shop, at that place.)
            if place == current && piece == nil {
                Task {
                    try? await Task.sleep(for: .milliseconds(30))
                    if let section {
                        scroll.glide(toSection: section, type: type, reduceMotion: reduceMotion)
                    } else {
                        scroll.glideToTop(reduceMotion: reduceMotion)
                    }
                }
            } else {
                app.open(place, at: section, type: type)
            }
        case .saved:
            app.tab = .saved
        case .home:
            app.tab = .home
            app.homePath = []
        case .link(let url):
            openURL(url)
        }
    }

    #if DEBUG
    /// For side-by-side screenshots with the prototype's directory: `-SOSPreviewDirectory Clothing` opens it on this
    /// page with that category unfolded (`-SOSPreviewDirectory open`, all folded). Debug builds only.
    private func openPreviewDirectory() async {
        guard let row = UserDefaults.standard.string(forKey: "SOSPreviewDirectory"), showsMap else { return }
        try? await Task.sleep(for: .milliseconds(1100))
        directory.open(fromLine: scroll.mode == .down)
        if row != "open" { directory.openRow = row }
    }
    #endif
}

/// A page under the site's header with one scrolling page in it (Home, Saved, the bag).
struct HeaderPage<Content: View>: View {
    var current: ShopPlace?
    var showsMap = true
    /// Pull to refresh fetches the closet again (APP-SPEC §3.1).
    var refresh: (@MainActor @Sendable () async -> Void)? = nil
    @ViewBuilder var content: (_ width: CGFloat) -> Content

    @State private var scroll = PageScroll()

    var body: some View {
        PageFrame(current: current, showsMap: showsMap, scroll: scroll) { width in
            PageScrollView(scroll: scroll, refresh: refresh, topRoom: showsMap ? SiteHeader.tabRowHeight : 0) {
                content(width)
                    .frame(width: width)
            }
        }
    }
}
