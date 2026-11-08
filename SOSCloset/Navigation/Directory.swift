import SwiftUI

/// The directory's state (SPEC §4): open or closed, whether the place line opened it, which department's plan it shows,
/// the one category unfolded, and the house row.
@MainActor @Observable final class DirectoryState {
    private(set) var isOpen = false
    /// Opened from the place line: the line folds into the round key showing ×.
    private(set) var fromLine = false
    /// The plan shown (nil: the page's own department, or Shop All's).
    var plan: ShopPlace?
    /// Which way the last change of plan went along the map, for the slide.
    private(set) var planDirection = 1
    /// The one category unfolded (one at a time), or nil.
    var openRow: String?
    var houseOpen = false

    /// It always opens with everything folded (Sam, October 22).
    func open(fromLine: Bool) {
        plan = nil
        openRow = nil
        houseOpen = false
        self.fromLine = fromLine
        isOpen = true
    }

    func close() {
        isOpen = false
    }

    func show(_ place: ShopPlace, from current: ShopPlace) {
        planDirection = place.rawValue >= current.rawValue ? 1 : -1
        openRow = nil
        plan = place
    }
}

/// Where a choice in the directory goes.
enum DirectoryChoice {
    /// A department (at a section, and a type in it), or its top.
    case place(ShopPlace, section: String?, type: String?)
    case saved
    case home
    case link(URL)
}

/// The directory (SPEC §4; the app prototype's ShopDirectory): one directory for the whole closet and the house, a
/// panel of clearer glass inset 8pt with 28pt corners just under the top row. Top to bottom: the map with a white lens,
/// "All of Women ›", the department's categories folded (one open at a time, All <category> first), Saved with its
/// count, and SOS Closet's house pages folded; a grabber at its foot flicks it closed. A band of the page stays in view
/// below it under a light veil, and tapping that band closes it.
struct DirectoryLayer: View {
    let state: DirectoryState
    /// The page it opened on (nil on Home, Saved and the bag).
    let page: ShopPlace?
    /// Where you are on that page.
    let section: String
    let type: String
    /// The panel's tallest: it stops at least 120pt (or 16% of the screen, whichever is more) above the bottom.
    let maxHeight: CGFloat
    let choose: (DirectoryChoice) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .top) {
            if state.isOpen {
                // A very light veil (6% ink): the page doesn't scroll behind it, and a tap on it closes the directory.
                Color.ink.opacity(0.06)
                    .ignoresSafeArea(edges: .bottom)
                    .contentShape(.rect)
                    .onTapGesture { state.close() }
                    // (VoiceOver closes it with the panel's own Close, or the escape gesture.)
                    .accessibilityHidden(true)
                    .transition(.opacity)
                DirectoryPanel(
                    state: state, page: page, section: section, type: type,
                    maxHeight: max(240, maxHeight), choose: choose
                )
                // (A panel of short rows: it grows with the text up to the largest standard size.)
                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                // While it's open, VoiceOver stays in it; the two-finger scrub closes it.
                .accessibilityAddTraits(.isModal)
                .accessibilityAction(.escape) { state.close() }
                .padding(.horizontal, 8)
                .padding(.top, 4)
                .transition(panelTransition)
            }
        }
        .animation(reduceMotion ? .easeOut(duration: 0.2) : (state.isOpen ? Motion.glassSpring(0.55) : .easeIn(duration: 0.24)), value: state.isOpen)
    }

    /// It pops open from the control that opened it, from ~92% with its origin there, coming into focus; it closes
    /// quickly, going out of focus. Reduce Motion: a fade.
    private var panelTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return .modifier(active: PanelPop(on: false), identity: PanelPop(on: true))
    }
}

private struct PanelPop: ViewModifier {
    let on: Bool
    func body(content: Content) -> some View {
        content
            .scaleEffect(on ? 1 : 0.92, anchor: UnitPoint(x: 0.08, y: 0))
            .blur(radius: on ? 0 : 8)
            .opacity(on ? 1 : 0)
    }
}

private struct DirectoryPanel: View {
    @Bindable var state: DirectoryState
    let page: ShopPlace?
    let section: String
    let type: String
    let maxHeight: CGFloat
    let choose: (DirectoryChoice) -> Void

    @Environment(Closet.self) private var closet
    @Environment(SavedPieces.self) private var saved
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var contentHeight: CGFloat = 400
    @State private var pull: CGFloat = 0

    private var shown: ShopPlace { state.plan ?? page ?? .all }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    map
                    plan
                        .id(shown)
                        .transition(planTransition)
                    savedRow
                        .padding(.top, 6)
                    houseRow
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)
                .padding(.bottom, 4)
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { contentHeight = $0 }
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.hidden)
            .frame(height: min(contentHeight, maxHeight - 24))
            grabber
        }
        .clipShape(.rect(cornerRadius: 28))
        .glassEffect(.regular, in: .rect(cornerRadius: 28))
        .offset(y: min(0, pull))
        .opacity(pull < 0 ? max(0.45, 1 + pull / 200) : 1)
        .animation(reduceMotion ? nil : Motion.easeOut(0.42), value: state.openRow)
        .animation(reduceMotion ? nil : Motion.easeOut(0.42), value: state.houseOpen)
        .animation(reduceMotion ? nil : Motion.easeOut(0.56), value: shown)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Directory")
    }

    private var planTransition: AnyTransition {
        if reduceMotion { return .opacity }
        let d = CGFloat(state.planDirection)
        return .asymmetric(
            insertion: .offset(x: 96 * d).combined(with: .opacity),
            removal: .offset(x: -56 * d).combined(with: .opacity).animation(.easeIn(duration: 0.24)))
    }

    // MARK: The map

    /// The tab row as a lighter strip inside the panel (never glass on glass), its own white lens on the department
    /// shown. Tapping another slides its plan in from its side of the map.
    private var map: some View {
        HStack(spacing: 0) {
            ForEach(ShopPlace.allCases) { place in
                let on = place == shown
                Button {
                    state.show(place, from: shown)
                } label: {
                    Text(place.label(narrow: false))
                        .textStyle(.directoryTab)
                        // (The map, like the tab row it copies, keeps its size.)
                        .dynamicTypeSize(...DynamicTypeSize.large)
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                        .fixedSize()
                        .padding(.horizontal, 9)
                        .frame(height: 32)
                        .background {
                            if on {
                                Capsule().fill(.paper)
                                    .shadow(color: Color.ink.opacity(0.18), radius: 4, y: 2)
                                    .overlay(Capsule().stroke(Color.ink.opacity(0.06), lineWidth: 0.5))
                            }
                        }
                        .contentShape(.capsule)
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? [.isSelected] : [])
                if place != ShopPlace.allCases.last { Spacer(minLength: 0) }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 40)
        .background(Capsule().fill(Color.ink.opacity(0.05)))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Departments")
    }

    // MARK: The plan

    private var model: ShopPageModel { Browse.page(shown, pieces: closet.pieces) }

    private var plan: some View {
        let m = model
        return VStack(alignment: .leading, spacing: 0) {
            Button {
                choose(.place(shown, section: nil, type: nil))
            } label: {
                HStack(spacing: 8) {
                    Text(shown == .all ? "All \(closet.pieces.filter(isPlaced).count) pieces" : "All of \(shown.label(narrow: false))")
                        .textStyle(.directoryAll)
                        .foregroundStyle(.ink)
                    SmallChevron()
                }
                .padding(.horizontal, 2)
                .frame(height: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            ForEach(rows(m), id: \.name) { row in
                categoryRow(row)
            }
        }
    }

    private struct Row {
        var name: String
        var tile: UIImage?
        /// Its types, when it folds (a category with one type is a link).
        var types: [String]
        var go: DirectoryChoice
    }

    private func rows(_ m: ShopPageModel) -> [Row] {
        switch shown {
        case .all:
            return Dept.allCases.compactMap { d in
                guard !deptPieces(closet.pieces, d).isEmpty else { return nil }
                return Row(
                    name: d.displayName, tile: Merch.deptTile[d].flatMap(TileImages.image(named:)), types: [],
                    go: .place(ShopPlace(d), section: nil, type: nil))
            }
        default:
            guard let dept = m.dept else { return [] }
            if m.isCase {
                // A case lists its categories alone; in phase 1 each opens the case at the top (they narrow with a tag
                // once Search exists, APP-SPEC §2).
                let cats = dept.categories.filter { c in m.casePieces.contains { $0.cat == c } }
                return cats.map { c in
                    Row(name: c, tile: TileImages.image(dept, c), types: [], go: .place(shown, section: nil, type: nil))
                }
            }
            return m.sections.map { s in
                Row(
                    name: s.name, tile: TileImages.image(dept, s.name),
                    types: s.types.count > 1 ? s.types.map(\.name) : [],
                    go: .place(shown, section: s.name, type: nil))
            }
        }
    }

    /// A category's row: its cutout, its name in spaced capitals (underlined where you are), and a chevron that turns
    /// over when it unfolds; unfolded, All <category> and then its types. A row with nothing to unfold is a link (›).
    private func categoryRow(_ row: Row) -> some View {
        let folds = !row.types.isEmpty
        let open = folds && state.openRow == row.name
        let here = shown == page && section == row.name && page != .all
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color.ink.opacity(0.06)).frame(height: 1)
            Button {
                if folds {
                    state.openRow = open ? nil : row.name
                } else {
                    choose(row.go)
                }
            } label: {
                HStack(spacing: 12) {
                    TileCutout(image: row.tile, small: true)
                        .frame(width: 40, height: 30)
                    Text(row.name)
                        .textStyle(.directoryRow)
                        .foregroundStyle(.ink)
                        .lineUnder(here, offset: 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DownChevron()
                        .rotationEffect(.degrees(folds ? (open ? 180 : 0) : -90))
                }
                .padding(.horizontal, 2)
                .frame(height: 54)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(folds ? (open ? "Expanded" : "Collapsed") : "")
            .accessibilityAddTraits(here ? [.isSelected] : [])
            if open {
                VStack(alignment: .leading, spacing: 0) {
                    item("All \(row.name)", strong: true, underlined: false) {
                        choose(.place(shown, section: row.name, type: nil))
                    }
                    ForEach(row.types, id: \.self) { t in
                        item(t, strong: false, underlined: here && type == t) {
                            choose(.place(shown, section: row.name, type: t))
                        }
                    }
                }
                .padding(.leading, 52)
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
    }

    private func item(_ words: String, strong: Bool, underlined: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(words)
                .textStyle(strong ? .directoryItemStrong : .directoryItem)
                .foregroundStyle(strong ? Color.ink : Color.ink2)
                .lineUnder(underlined, offset: 5)
                .frame(height: 38, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(underlined ? [.isSelected] : [])
    }

    // MARK: The house

    /// Saved, with its heart and its count.
    private var savedRow: some View {
        Button { choose(.saved) } label: {
            HStack(spacing: 0) {
                HeartShape()
                    .stroke(.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 20)
                    .padding(.horizontal, 10)
                Text("Saved")
                    .textStyle(.directoryItem)
                    .foregroundStyle(.ink)
                Spacer(minLength: 8)
                Text("\(saved.count(in: closet))")
                    .textStyle(.directoryQuiet)
                    .foregroundStyle(.muted)
                    .monospacedDigit()
            }
            .padding(.horizontal, 2)
            .frame(height: 52)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .top) { Rectangle().fill(Color.ink.opacity(0.06)).frame(height: 1) }
        .accessibilityLabel("Saved, \(saved.count(in: closet))")
    }

    /// SOS Closet's house pages, folded: Objects with a past (Home), The Archive, Consign with us and About in two
    /// columns, then the quiet line.
    private var houseRow: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(Color.ink.opacity(0.06)).frame(height: 1)
            Button { state.houseOpen.toggle() } label: {
                HStack(spacing: 0) {
                    Text("SOS Closet")
                        .textStyle(.directoryHouse)
                        .foregroundStyle(.ink)
                        .padding(.leading, 52)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    DownChevron()
                        .rotationEffect(.degrees(state.houseOpen ? 180 : 0))
                }
                .padding(.horizontal, 2)
                .frame(height: 52)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(state.houseOpen ? "Expanded" : "Collapsed")
            if state.houseOpen {
                VStack(alignment: .leading, spacing: 0) {
                    Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 0) {
                        GridRow {
                            house("Objects with a past") { choose(.home) }
                            house("The Archive", action: nil)
                        }
                        GridRow {
                            house("Consign with us") {
                                choose(.link(URL(string: "mailto:\(Merch.contact.email)?subject=Consignment")!))
                            }
                            house("About", action: nil)
                        }
                    }
                    Text("Shipping · Returns · Authentication · Contact")
                        .textStyle(.directoryQuiet)
                        .foregroundStyle(.muted)
                        .padding(.top, 2)
                        .padding(.bottom, 14)
                }
                .padding(.leading, 52)
                .transition(.opacity.combined(with: .offset(y: -6)))
            }
        }
    }

    @ViewBuilder private func house(_ words: String, action: (() -> Void)?) -> some View {
        let text = Text(words)
            .textStyle(.directoryItem)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        if let action {
            Button(action: action) { text.contentShape(.rect) }.buttonStyle(.plain)
        } else {
            text
        }
    }

    // MARK: The grabber

    /// 36 × 5pt in a 24pt strip at the foot. Dragging up moves the directory with the finger (fading to no less than
    /// 45%); let go past a quarter of its height (at most 140pt) or with a quick flick and it closes, otherwise it
    /// springs back. Reduce Motion: it closes at once.
    private var grabber: some View {
        Capsule()
            .fill(.lineStrong)
            .frame(width: 36, height: 5)
            .frame(maxWidth: .infinity)
            .frame(height: 24)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { pull = min(0, $0.translation.height) }
                    .onEnded { g in
                        let far = -g.translation.height > min(140, (contentHeight + 24) / 4)
                        let quick = g.velocity.height < -450
                        if far || quick {
                            state.close()
                            Task { try? await Task.sleep(for: .milliseconds(300)); pull = 0 }
                        } else {
                            withAnimation(reduceMotion ? nil : Motion.glassSpring(0.45)) { pull = 0 }
                        }
                    }
            )
            .accessibilityLabel("Close the directory")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { state.close() }
            .accessibilityAction { state.close() }
    }
}

extension View {
    /// The site's underline: 1pt of ink, `offset` below the words (`text-underline-offset`).
    func lineUnder(_ on: Bool, offset: CGFloat) -> some View {
        overlay(alignment: .bottom) {
            if on { Rectangle().fill(.ink).frame(height: 1).offset(y: offset) }
        }
    }
}

/// The directory's small chevrons: › after "All of Women" (6 × 10pt), and the rows' down-chevron (16pt, 2pt stroke
/// in a 24-unit box).
private struct SmallChevron: View {
    var body: some View {
        Polyline(box: CGSize(width: 6, height: 10), points: [(1, 1), (5, 5), (1, 9)])
            .stroke(.muted, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
            .frame(width: 6, height: 10)
            .accessibilityHidden(true)
    }
}

private struct DownChevron: View {
    var body: some View {
        Polyline(box: CGSize(width: 24, height: 24), points: [(6, 9.5), (12, 15.5), (18, 9.5)])
            .stroke(.ink2, style: StrokeStyle(lineWidth: 1.33, lineCap: .round, lineJoin: .round))
            .frame(width: 16, height: 16)
            .accessibilityHidden(true)
    }
}
