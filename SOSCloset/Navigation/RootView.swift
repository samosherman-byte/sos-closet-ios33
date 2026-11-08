import SwiftUI

/// The app's places in the system's floating Liquid Glass tab bar (APP-SPEC §7; Sam, October 24: "it should absolutely
/// be native liquid glass tab bar"): Home, Shop, Saved and Bag, the bag's count as a small black badge. Monochrome:
/// the selected tab is ink, no tint (SPEC §12: brand color lives in the content). Scrolling down it shrinks to the
/// current tab, and scrolling up brings it back (the system's minimize behavior). Search joins it in phase 2 as its
/// own round button.
struct RootView: View {
    @State private var app = AppState()
    /// The closet, from this build's store: fetched when the app opens and again when it comes back after a minute or
    /// more (APP-SPEC §3.1, Freshness).
    @State private var closet = Closet.forThisBuild()
    /// The hearted pieces, kept on the phone (APP-SPEC §3.8).
    @State private var saved = SavedPieces()
    /// The bag: Sam's store's cart, or the sample store's list (APP-SPEC §3.7).
    @State private var bag = Bag.forThisBuild()
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        @Bindable var app = app
        @Bindable var bag = bag
        TabView(selection: $app.tab) {
            Tab(value: AppTab.home) {
                NavigationStack(path: $app.homePath) { HomeView().pieceDestinations() }
            } label: {
                tabLabel("Home", symbol: "house", for: .home)
            }
            Tab(value: AppTab.shop) {
                NavigationStack(path: $app.shopPath) { ShopView().pieceDestinations() }
            } label: {
                tabLabel("Shop", symbol: "hanger", for: .shop)
            }
            Tab(value: AppTab.saved) {
                NavigationStack(path: $app.savedPath) { SavedView().pieceDestinations() }
            } label: {
                tabLabel("Saved", symbol: "heart", for: .saved)
            }
            Tab(value: AppTab.bag) {
                NavigationStack(path: $app.bagPath) { BagView().pieceDestinations() }
            } label: {
                tabLabel("Bag", symbol: "bag", for: .bag)
            }
            // (The badge gives VoiceOver the count: "Bag, 2 items".)
            .badge(bag.count)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.ink)
        // Adding a piece opens the bag: a sheet from the bottom, half height then full, glass at half height, swiped
        // down to close (APP-SPEC §3.7, §4). Checkout opens over it, or over the Bag tab.
        .sheet(item: $bag.sheet) { added in
            BagSheet(added: added)
                // (At the largest text sizes half a screen holds little more than the piece: it opens full height.)
                .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium, .large])
                .presentationDragIndicator(.visible)
                // A panel: the thicker system material (APP-SPEC §4), so what's behind it shows as a soft blur, not
                // its colors.
                .presentationBackground(.thickMaterial)
                .checkout(over: .sheet)
                .environment(app)
                .environment(closet)
                .environment(saved)
                .environment(bag)
        }
        .checkout(over: .page)
        .environment(app)
        .environment(closet)
        .environment(saved)
        .environment(bag)
        .task {
            await closet.load()
            #if DEBUG
            openPreviewPiece()
            #endif
        }
        .task { await bag.load() }
        .onChange(of: scenePhase) { _, phase in
            _ = closet.scenePhaseChanged(to: phase)
            bag.scenePhaseChanged(to: phase)
        }
    }

    #if DEBUG
    /// For side-by-side screenshots with the prototype's product page: `-SOSPreviewTab shop -SOSPreviewPiece jackie`
    /// opens that piece's page (by its id or handle) once the closet is in. Debug builds only.
    private func openPreviewPiece() {
        guard let key = UserDefaults.standard.string(forKey: "SOSPreviewPiece"),
            let piece = closet.piece(id: key) ?? closet.piece(handle: key)
        else { return }
        var now = Transaction()
        now.disablesAnimations = true
        withTransaction(now) { app.open(piece) }
    }
    #endif

    /// Outlined, and filled only when selected, as in the app prototype (the system would fill them all). The hanger
    /// has no filled form, so Shop stays a line drawing, as there.
    private func tabLabel(_ title: String, symbol: String, for tab: AppTab) -> some View {
        let on = app.tab == tab
        return Label(title, systemImage: on && symbol != "hanger" ? symbol + ".fill" : symbol)
            .environment(\.symbolVariants, .none)
    }
}
