import SwiftUI

/// The compact tile row a page hands its header, for the way back up.
struct CompactTiles {
    var dept: Dept
    var categories: [String]
    var onPick: (String) -> Void
}

/// The site's header at the top of Home and Shop (APP-SPEC §7; SPEC §3): the classic flat header on white. The top
/// row is Menu on the left and the logo in the middle (Search and Bag are in the tab bar), and under it the tab row,
/// the map, between hairlines.
///
/// Scrolling down, the tabs dematerialize; on a Shop page the key becomes the place line in Liquid Glass and the logo
/// dissolves; elsewhere Menu and the logo stay, plain, on the system's scroll edge effect. Scrolling back up brings the
/// flat band and the tabs back, with the compact tile row hanging under them on a page with a tile row. While the
/// directory is open the key shows × (the place line folds back into it) and the logo comes back.
///
/// It's drawn in two parts. The top row sits in the page's `safeAreaBar`, so the scroll edge effect is the system's own
/// and covers only the top row, as the site's band does. The tab row (and the compact row under it) hangs below it over
/// the page, which keeps the tab row's room empty at its top: so the page never jumps when the tabs go, and a heading
/// that lands just under the top row isn't faded by the edge effect.
struct SiteHeader: View {
    enum Part { case bar, tabs }
    /// Which part this is: the top row (in the `safeAreaBar`) or the tab row and the compact row (hanging under it).
    var part: Part = .bar
    /// The page's tab, underlined; nil on Home, where no tab is.
    let current: ShopPlace?
    let mode: HeaderMode
    /// Pages without the tab row (Saved, Bag) show their flat band until they're scrolled.
    var scrolled = false
    let width: CGFloat
    /// Home and Shop have the tab row under the top row; Saved and the bag have the top row alone.
    var showsMap = true
    /// Shop pages: where you are, for the place line (nil elsewhere: no place line).
    var place: PlaceWords? = nil
    var rollFrom: Edge = .bottom
    /// A page with a tile row: its compact copy, for the way back up.
    var compact: CompactTiles? = nil
    var compactCurrent = ""
    var directoryOpen = false
    let onMenu: () -> Void
    var onPlace: () -> Void = {}
    let onPick: (ShopPlace) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Namespace private var underline

    /// The top row and the tab row (SPEC §3: 44pt each, the tab row between a soft hairline and a hairline).
    static let rowHeight: CGFloat = 44
    static let tabRowHeight: CGFloat = 1 + rowHeight + 1
    static let height: CGFloat = rowHeight + tabRowHeight

    private var narrow: Bool { width < Layout.narrowWidth }
    private var tabsShown: Bool { showsMap ? mode != .down : !scrolled }
    private var lineOn: Bool { mode == .down && place != nil && !directoryOpen }
    private var compactOn: Bool { mode == .up && compact != nil && !directoryOpen }

    var body: some View {
        Group {
            switch part {
            case .bar:
                topRow
                    .background(alignment: .top) { band }
            case .tabs:
                VStack(spacing: 0) {
                    if showsMap { tabRow }
                    compactRow
                }
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.32), value: tabsShown)
        .animation(reduceMotion ? .easeOut(duration: 0.2) : .easeOut(duration: 0.32), value: compactOn)
    }

    // MARK: The top row

    private var topRow: some View {
        ZStack(alignment: .leading) {
            logo
                .frame(maxWidth: .infinity)
                .opacity(lineOn ? 0 : 1)
                .blur(radius: lineOn && !reduceMotion ? 8 : 0)
                .animation(.easeOut(duration: 0.3), value: lineOn)
            key
                .padding(.leading, 12)
                .opacity(lineOn ? 0 : 1)
                .blur(radius: lineOn && !reduceMotion ? 6 : 0)
                .allowsHitTesting(!lineOn)
                .accessibilityHidden(lineOn)
                .animation(.easeOut(duration: 0.3).delay(lineOn ? 0 : 0.1), value: lineOn)
            if let place, lineOn {
                PlaceLine(words: place, rollFrom: rollFrom, room: width - 32 - PlaceLine.chrome, action: onPlace)
                    .frame(maxWidth: width - 32, alignment: .leading)
                    .padding(.leading, 16)
                    .transition(lineTransition)
            }
        }
        .frame(height: Self.rowHeight)
        .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.glassSpring(0.6), value: lineOn)
    }

    /// The key: Menu (two short lines) at rest, × while the directory is open. Over the pieces, with the tabs away, the
    /// × sits on glass (the place line folded back into it).
    private var key: some View {
        Button(action: onMenu) {
            Group {
                if directoryOpen { CloseIcon() } else { MenuIcon() }
            }
            .frame(width: 42, height: 42)
            .contentShape(.circle)
            .glassEffect(directoryOpen && mode == .down ? .regular.interactive() : .identity, in: .circle)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(directoryOpen ? "Close the directory" : "Menu")
    }

    /// The line stretches out of the key on the glass spring as the Menu icon goes out of focus; the words come into
    /// focus a beat behind. Reduce Motion: it fades.
    private var lineTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .modifier(active: LineGrow(on: false), identity: LineGrow(on: true))
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

    /// Between a soft hairline above and a hairline below, on the flat white band; it dematerializes as it goes (fade,
    /// 94%, blur 6pt, ~.32s) and the band and its hairlines go with it.
    private var tabRow: some View {
        HStack(spacing: 0) {
            ForEach(ShopPlace.allCases) { place in
                tab(place)
                if place != ShopPlace.allCases.last { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, Layout.gutter(forWidth: width))
        .frame(height: Self.rowHeight)
        .opacity(tabsShown ? 1 : 0)
        .scaleEffect(tabsShown || reduceMotion ? 1 : 0.94)
        .blur(radius: tabsShown || reduceMotion ? 0 : 6)
        .padding(.vertical, 1)
        .background {
            Rectangle().fill(.paper)
                .overlay(alignment: .top) { Rectangle().fill(.lineSoft).frame(height: 1) }
                .overlay(alignment: .bottom) { Rectangle().fill(.line).frame(height: 1) }
                .opacity(tabsShown ? 1 : 0)
        }
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

    // MARK: The compact tile row

    /// Only on the way up, hanging from the header; it appears and leaves with the tabs, dematerializing the same way
    /// (fade, 97%, blur 6pt). Reduce Motion: it fades only.
    @ViewBuilder private var compactRow: some View {
        if let compact {
            CompactTileRow(
                dept: compact.dept, categories: compact.categories, current: compactCurrent, width: width,
                onPick: compact.onPick
            )
            .opacity(compactOn ? 1 : 0)
            .scaleEffect(compactOn || reduceMotion ? 1 : 0.97, anchor: .top)
            .blur(radius: compactOn || reduceMotion ? 0 : 6)
            .allowsHitTesting(compactOn)
            .accessibilityHidden(!compactOn)
        }
    }

    // MARK: The flat band

    /// The white band behind the top row while the tabs show (SPEC §3: no glass in the header at rest). When the tabs
    /// make way it goes, and the system's scroll edge effect is behind the top row.
    private var band: some View {
        Rectangle()
            .fill(.paper)
            .ignoresSafeArea(edges: .top)
            .opacity(tabsShown ? 1 : 0)
            .allowsHitTesting(false)
    }
}

/// The place line growing out of the key: from 60% at its leading end, out of focus, on the glass spring.
private struct LineGrow: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1 : 0.6, anchor: .leading)
            .blur(radius: on ? 0 : 6)
            .opacity(on ? 1 : 0)
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

/// The × Menu turns into while the directory is open (the site's `I_CLOSE`: 6.5 to 17.5 both ways, a 1.6 stroke).
private struct CloseIcon: View {
    var body: some View {
        Canvas { context, size in
            let k = size.width / 24
            var path = Path()
            path.move(to: CGPoint(x: 6.5 * k, y: 6.5 * k)); path.addLine(to: CGPoint(x: 17.5 * k, y: 17.5 * k))
            path.move(to: CGPoint(x: 17.5 * k, y: 6.5 * k)); path.addLine(to: CGPoint(x: 6.5 * k, y: 17.5 * k))
            context.stroke(path, with: .color(.ink), style: StrokeStyle(lineWidth: 1.6 * k, lineCap: .round))
        }
        .frame(width: 22, height: 22)
    }
}
