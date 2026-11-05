import SwiftUI

/// The site's header at the top of Home and Shop (APP-SPEC §7; SPEC §3): the classic flat header on white. The top
/// row is Menu on the left and the logo in the middle (Search and Bag are in the tab bar), and under it the tab row,
/// the map, between hairlines. Scrolling down, the tabs dematerialize and Menu and the logo stay, plain, on the
/// system's scroll edge effect; scrolling back up brings the flat band and the tabs back.
///
/// It sits in the page's `safeAreaBar`, so the scroll edge effect is the system's own. The tab row keeps its room while
/// it's away, so the page under it never jumps.
struct SiteHeader: View {
    /// The page's tab, underlined; nil on Home, where no tab is.
    let current: ShopPlace?
    /// The tabs (and the flat band behind the header) are showing: at the top of a page and while scrolling back up.
    /// On a page without the tab row (Saved, Bag), the flat band shows until the page is scrolled.
    let tabsShown: Bool
    let width: CGFloat
    /// Home and Shop have the tab row under the top row; Saved and the bag have the top row alone.
    var showsMap = true
    let onMenu: () -> Void
    let onPick: (ShopPlace) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var underline

    /// The top row and the tab row (SPEC §3: 44pt each, the tab row between a soft hairline and a hairline).
    static let rowHeight: CGFloat = 44
    static let height: CGFloat = rowHeight + 1 + rowHeight + 1

    private var narrow: Bool { width < Layout.narrowWidth }

    var body: some View {
        VStack(spacing: 0) {
            topRow
            if showsMap { tabRow }
        }
        .background(alignment: .top) { band }
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.32), value: tabsShown)
    }

    // MARK: The top row

    private var topRow: some View {
        ZStack {
            logo
            HStack(spacing: 0) {
                Button(action: onMenu) {
                    MenuIcon()
                        .frame(width: 42, height: 42)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Menu")
                .padding(.leading, 12)
                Spacer(minLength: 0)
            }
        }
        .frame(height: Self.rowHeight)
    }

    /// SOS CLOSET in Tenor Sans, wide letter spacing (the site's `.logo`; SPEC §3). Tracking adds space after the last
    /// letter too, so the same space before the first keeps the word centred, as the site's `padding-left` does.
    private var logo: some View {
        let style: TextStyle = narrow ? .logoNarrow : width <= 420 ? .logoPhone : .logo
        return Text("SOS Closet")
            .textStyle(style)
            .foregroundStyle(.ink)
            .lineLimit(1)
            .fixedSize()
            .padding(.leading, style.tracking * style.size)
            .accessibilityAddTraits(.isHeader)
            .accessibilityLabel("SOS Closet")
    }

    // MARK: The tab row

    private var tabRow: some View {
        VStack(spacing: 0) {
            Rectangle().fill(.lineSoft).frame(height: 1)
            HStack(spacing: 0) {
                ForEach(ShopPlace.allCases) { place in
                    tab(place)
                    if place != ShopPlace.allCases.last { Spacer(minLength: 0) }
                }
            }
            .padding(.horizontal, Layout.gutter(forWidth: width))
            .frame(height: Self.rowHeight)
        }
        .opacity(tabsShown ? 1 : 0)
        .scaleEffect(tabsShown || reduceMotion ? 1 : 0.94)
        .blur(radius: tabsShown || reduceMotion ? 0 : 6)
        .allowsHitTesting(tabsShown)
        .accessibilityHidden(!tabsShown)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Departments")
    }

    private func tab(_ place: ShopPlace) -> some View {
        let on = place == current
        return Button { onPick(place) } label: {
            Text(place.label(narrow: narrow))
                .textStyle(narrow ? .tabNarrow : .tab)
                .foregroundStyle(.ink)
                .lineLimit(1)
                .fixedSize()
                .frame(maxHeight: .infinity)
                // One thin ink underline, 7pt above the row's lower hairline and as wide as the words; it glides from
                // tab to tab (~550ms) and is under no tab on Home (SPEC §3).
                .overlay(alignment: .bottom) {
                    if on {
                        Rectangle()
                            .fill(.ink)
                            .frame(height: 1)
                            .matchedGeometryEffect(id: "underline", in: underline)
                            .padding(.bottom, 7)
                    }
                }
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .timingCurve(0.3, 0.8, 0.25, 1, duration: 0.55), value: current)
        .accessibilityAddTraits(on ? [.isSelected] : [])
    }

    // MARK: The flat band

    /// The white band behind the header while the tabs show, with its hairline (SPEC §3: no glass in the header at
    /// rest). When the tabs make way it goes, and the system's scroll edge effect is behind Menu and the logo.
    private var band: some View {
        Rectangle()
            .fill(.paper)
            .overlay(alignment: .bottom) { if showsMap { Rectangle().fill(.line).frame(height: 1) } }
            .ignoresSafeArea(edges: .top)
            .opacity(tabsShown ? 1 : 0)
            .allowsHitTesting(false)
    }
}

/// The site's Menu icon: two short lines (24-unit box, lines from 5 to 19 at 9.5 and 14.5, a 1.6 stroke, drawn at 22pt).
private struct MenuIcon: View {
    var body: some View {
        Canvas { context, size in
            let k = size.width / 24
            var path = Path()
            path.move(to: CGPoint(x: 5 * k, y: 9.5 * k)); path.addLine(to: CGPoint(x: 19 * k, y: 9.5 * k))
            path.move(to: CGPoint(x: 5 * k, y: 14.5 * k)); path.addLine(to: CGPoint(x: 19 * k, y: 14.5 * k))
            context.stroke(path, with: .color(.ink), style: StrokeStyle(lineWidth: 1.6 * k, lineCap: .round))
        }
        .frame(width: 22, height: 22)
    }
}

/// Follows the page's scroll the way the site's header does (SPEC §3): the tabs make way once you're more than 160pt
/// down and heading down, and come back when you head up by more than 8pt or reach the top.
struct HeaderScroll: Equatable {
    private var anchor: CGFloat = 0
    private var headingDown = true
    private(set) var tabsShown = true

    /// How far down the tabs start to make way on pages with no tile row (Home, Shop All, a piece's page).
    static let threshold: CGFloat = 160

    mutating func update(offset y: CGFloat) {
        if headingDown {
            if y > anchor { anchor = y } else if y < anchor - 8 { headingDown = false; anchor = y }
        } else {
            if y < anchor { anchor = y } else if y > anchor + 8 { headingDown = true; anchor = y }
        }
        tabsShown = !(y > Self.threshold && headingDown)
    }
}
