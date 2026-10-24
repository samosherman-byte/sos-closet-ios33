import SwiftUI

/// The places side by side, one screen each (SPEC §1.1, §6: departments sit side by side), swiped between under the
/// finger or glided to from a tab, always along the map. It's the iPhone's own paging, so a swipe follows the finger
/// 1:1, can be caught mid-move, and settles on one page; each page keeps its own place when you come back (SPEC §1.5).
struct PlacePager: View {
    let places: [Place]
    @Binding var current: Place
    /// Where the pager is along the map, as a place's position (1.4 = between Women and Men), following the finger.
    @Binding var position: CGFloat
    /// The height of the header over each page, so each page's own scroll edge effect sits under it.
    let barHeight: CGFloat
    /// Room at the top of a page's content for what the header covers only at rest (direction A's tab row).
    var topPadding: CGFloat = 0
    /// Each page's vertical scroll, as (place, old offset, new offset).
    var onScroll: (Place, CGFloat, CGFloat) -> Void = { _, _, _ in }

    @State private var shown: Place?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(places: [Place], current: Binding<Place>, position: Binding<CGFloat>, barHeight: CGFloat, topPadding: CGFloat = 0,
         onScroll: @escaping (Place, CGFloat, CGFloat) -> Void = { _, _, _ in }) {
        self.places = places
        _current = current
        _position = position
        self.barHeight = barHeight
        self.topPadding = topPadding
        self.onScroll = onScroll
        _shown = State(initialValue: current.wrappedValue)
    }

    var body: some View {
        ScrollViewReader { proxy in
            pages
                // Open on the current place (the scroll position alone doesn't move the pager before its first layout).
                .onAppear { proxy.scrollTo(current, anchor: .leading) }
        }
    }

    private var pages: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(places) { place in
                    PlacePage(place: place, barHeight: barHeight, topPadding: topPadding) { old, new in
                        if place == current { onScroll(place, old, new) }
                    }
                    .containerRelativeFrame(.horizontal)
                    .id(place)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $shown)
        .scrollIndicators(.hidden)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.x / max(1, geometry.containerSize.width)
        } action: { _, offset in
            position = CGFloat(places[0].rawValue) + offset
        }
        .onChange(of: shown) { _, page in
            if let page, page != current { current = page }
        }
        .onChange(of: current) { _, place in
            guard shown != place else { return }
            // A tab or the logo: the page glides there along the map (the phone push's curve), or jumps with Reduce Motion.
            withAnimation(reduceMotion ? nil : Motion.push(0.52)) { shown = place }
        }
    }
}

/// One place's page: its own vertical scroll, under the header's bar.
private struct PlacePage: View {
    let place: Place
    let barHeight: CGFloat
    let topPadding: CGFloat
    let onScroll: (CGFloat, CGFloat) -> Void

    @State private var scroll = ScrollPosition(edge: .top)

    var body: some View {
        ScrollView(.vertical) {
            QuickPage(place: place, topPadding: topPadding)
        }
        .scrollPosition($scroll)
        // A bar the header's height, with nothing to see: it gives the page its inset and the system scroll edge effect
        // under the header, which floats above the pager so it stays put while the pages slide. (A fully clear bar
        // gets no edge effect, so it's white at 1%, which shows on nothing.)
        .safeAreaBar(edge: .top) { Color.paper.opacity(0.01).frame(height: barHeight).allowsHitTesting(false) }
        .scrollEdgeEffectStyle(Demo.edgeStyle, for: .top)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentOffset.y + geometry.contentInsets.top
        } action: { old, new in
            onScroll(old, new)
        }
        .task { await Demo.scroll(place, with: $scroll) }
    }
}
