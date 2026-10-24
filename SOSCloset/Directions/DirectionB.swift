import SwiftUI

/// Direction B (APP-SPEC §7): native iOS, the way Apple's own Store app is built. A Liquid Glass tab bar at the
/// bottom (Home, Shop, Saved, Bag; Search joins it later as its own round tab), drawn and animated by the system,
/// which shrinks while you scroll down. Shop holds the map: the logo, then the departments as a row whose underline
/// follows a swipe between them. Saved and Bag are a tap away from anywhere, with the bag's count on its tab.
struct DirectionB: View {
    enum Section: String, Hashable { case home, shop, saved, bag }

    @State private var section: Section = Demo.section.flatMap(Section.init(rawValue:)) ?? .shop
    @State private var current: Place = Demo.page.flatMap { $0 == .home ? nil : $0 } ?? .shopAll
    @State private var position: CGFloat = CGFloat((Demo.page.flatMap { $0 == .home ? nil : $0 } ?? .shopAll).rawValue)

    var body: some View {
        TabView(selection: $section) {
            Tab("Home", systemImage: "house", value: Section.home) {
                HomeTab()
            }
            Tab("Shop", systemImage: "hanger", value: Section.shop) {
                ShopTab(current: $current, position: $position)
            }
            Tab("Saved", systemImage: "heart", value: Section.saved) {
                EmptyTab(systemName: "heart", title: "Nothing saved yet",
                         line: "Tap the heart on any piece to keep it here.")
            }
            Tab("Bag", systemImage: "bag", value: Section.bag) {
                EmptyTab(systemName: "bag", title: "Your bag is empty",
                         line: "Every piece is one of one and isn't held until you check out.")
            }
            .badge(0)
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tint(.ink)
        .sensoryFeedback(.selection, trigger: section)
    }
}

/// Shop: the departments side by side, under the logo and the department row, which sit on the scroll edge effect.
private struct ShopTab: View {
    @Binding var current: Place
    @Binding var position: CGFloat

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .top) {
                PlacePager(places: Place.tabs, current: $current, position: $position, barHeight: 88)
                VStack(spacing: 0) {
                    Logo(width: geometry.size.width)
                        .frame(height: 44)
                        .accessibilityAddTraits(.isHeader)
                    TabRow(width: geometry.size.width, position: position) { current = $0 }
                }
            }
        }
        .background(.paper)
        .sensoryFeedback(.selection, trigger: current)
    }
}

private struct HomeTab: View {
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                QuickPage(place: .home)
            }
            .safeAreaBar(edge: .top) {
                Logo(width: geometry.size.width).frame(maxWidth: .infinity).frame(height: 44)
            }
        }
        .background(.paper)
    }
}

private struct EmptyTab: View {
    let systemName: String
    let title: String
    let line: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: systemName).font(.system(size: 30, weight: .light)).foregroundStyle(.muted)
            Text(title).textStyle(.categoryHeading).foregroundStyle(.ink)
            Text(line).textStyle(.cardName).foregroundStyle(.ink2).multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.paper)
    }
}
