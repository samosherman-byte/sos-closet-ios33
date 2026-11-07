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
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var app = app
        TabView(selection: $app.tab) {
            Tab(value: AppTab.home) {
                NavigationStack { HomeView() }
            } label: {
                tabLabel("Home", symbol: "house", for: .home)
            }
            Tab(value: AppTab.shop) {
                NavigationStack { ShopView() }
            } label: {
                tabLabel("Shop", symbol: "hanger", for: .shop)
            }
            Tab(value: AppTab.saved) {
                NavigationStack { SavedView() }
            } label: {
                tabLabel("Saved", symbol: "heart", for: .saved)
            }
            Tab(value: AppTab.bag) {
                NavigationStack { BagView() }
            } label: {
                tabLabel("Bag", symbol: "bag", for: .bag)
            }
            .badge(app.bagCount)
            .accessibilityLabel(app.bagCount == 0 ? "Bag" : "Bag, \(app.bagCount) \(app.bagCount == 1 ? "piece" : "pieces")")
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.ink)
        .environment(app)
        .environment(closet)
        .environment(saved)
        .task { await closet.load() }
        .onChange(of: scenePhase) { _, phase in _ = closet.scenePhaseChanged(to: phase) }
    }

    /// Outlined, and filled only when selected, as in the app prototype (the system would fill them all). The hanger
    /// has no filled form, so Shop stays a line drawing, as there.
    private func tabLabel(_ title: String, symbol: String, for tab: AppTab) -> some View {
        let on = app.tab == tab
        return Label(title, systemImage: on && symbol != "hanger" ? symbol + ".fill" : symbol)
            .environment(\.symbolVariants, .none)
    }
}
