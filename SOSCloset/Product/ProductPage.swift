import SwiftUI
import UIKit

/// A piece's page (APP-SPEC §3.5; SPEC §10): compact, and the designer leads. Under the logo row, Back and the place
/// line (WOMEN / Handbags), flat on the page at rest and floating up into the top row in glass as you scroll; then the
/// photos, the designer and the piece's name, the price with its status, the description, Add to Bag with the heart,
/// the two lines about the house, Details and Shipping & returns folded, and "You may also like". The tab bar stays,
/// Shop selected (on Home, Home).
///
/// It shows at once with what the card knew, the closet's own copy of the piece, and the store's full answer fills in
/// the rest (on Shopify, the description and the written details).
struct ProductPage: View {
    let route: PieceRoute

    @Environment(Closet.self) private var closet
    @Environment(AppState.self) private var app
    @Environment(\.dismiss) private var dismiss
    @State private var scroll = PageScroll(threshold: 160)
    @State private var detail: ProductDetail?
    /// The store's full answer is in (or couldn't be had): only then does an empty description fall back to words.
    @State private var complete = false
    /// The photo in view.
    @State private var photo: Int

    init(route: PieceRoute) {
        self.route = route
        _photo = State(initialValue: route.photo)
    }

    var body: some View {
        let piece = detail?.piece ?? closet.piece(handle: route.piece.handle) ?? route.piece
        PageFrame(current: nil, scroll: scroll, piece: top(piece)) { width in
            PageScrollView(scroll: scroll, topRoom: SiteHeader.pieceRowHeight) {
                ProductContent(
                    piece: piece, detail: detail, complete: complete, width: width, scroll: scroll, photo: $photo)
                    .frame(width: width)
            }
        }
        .task(id: route.piece.handle) { await load() }
        .onChange(of: photo) { _, k in remember(k) }
        .onAppear { remember(photo) }
    }

    /// Where the piece lives, for Back and the place line: its department and category (on a phone the line stops at the
    /// category, SPEC §10).
    private func top(_ piece: Piece) -> PieceTop {
        let place = piece.dept.map(ShopPlace.init)
        return PieceTop(
            words: PlaceWords(dept: place?.label(narrow: false) ?? "Shop All", section: piece.cat ?? "", type: ""),
            place: place, section: piece.cat ?? "", back: { dismiss() })
    }

    private func load() async {
        if detail == nil { detail = closet.cachedDetail(handle: route.piece.handle) }
        if let full = try? await closet.productDetail(handle: route.piece.handle) { detail = full }
        complete = true
    }

    /// The photo in view, for the card to turn to before the page zooms back into it (SPEC §5): only the piece's own
    /// photos are on its card.
    private func remember(_ k: Int) {
        guard let id = route.zoomID else { return }
        let onCard = 1 + (route.piece.morePhotos?.count ?? 0)
        let back = TurnBack(zoomID: id, photo: k < onCard ? k : 0)
        if app.turnBack != back { app.turnBack = back }
    }
}

/// The page under the header.
private struct ProductContent: View {
    let piece: Piece
    let detail: ProductDetail?
    let complete: Bool
    let width: CGFloat
    let scroll: PageScroll
    @Binding var photo: Int

    @Environment(Closet.self) private var closet

    /// The photos before the store's answer is in: the cover and the others the card swipes through.
    private var look: [PieceImage] {
        if let detail, !detail.photos.isEmpty { return detail.photos }
        guard let cover = piece.image else { return [] }
        return [cover] + (piece.morePhotos ?? []).map { PieceImage(url: $0.url, alt: "", width: $0.width) }
    }

    var body: some View {
        let also = alsoLike(piece, closet.pieces)
        VStack(alignment: .leading, spacing: 0) {
            ProductGallery(look: look, proof: detail?.proof ?? [], width: width, at: $photo)
            ProductInfo(piece: piece, detail: detail, complete: complete, width: width, scroll: scroll)
                .padding(.horizontal, Layout.gutter(forWidth: width))
                .padding(.top, 24)
            if !also.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    SectionHeading(name: "You may also like", opens: nil)
                    PieceGrid(pieces: also, width: width)
                        .padding(.top, 16)
                }
                .padding(.top, 48)
                .environment(\.zoomContext, "also|" + piece.id)
            }
        }
        .padding(.bottom, 56)
    }
}

// MARK: - The words and the buttons

private struct ProductInfo: View {
    let piece: Piece
    let detail: ProductDetail?
    let complete: Bool
    let width: CGFloat
    let scroll: PageScroll

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var detailsOpen = false
    @State private var shipOpen = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(piece.designer)
                .textStyle(.productDesigner)
                .foregroundStyle(.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(piece.title)
                .textStyle(.productName)
                .foregroundStyle(.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
                .padding(.top, 10)
            PriceLine(price: moneyText(piece.price), marks: detail.map { statusMarks(StatusFacts($0)) } ?? [])
                .padding(.top, 18)
            ProductDescription(blocks: blocks, scroll: scroll)
                .id(piece.id + (detail?.descriptionHtml.isEmpty == false ? "|full" : ""))
                .padding(.top, 14)
            BagRow(piece: piece, detail: detail)
                .padding(.top, 24)
            note
                .padding(.top, 14)
            folds
                .padding(.top, 22)
        }
    }

    /// The description's blocks; with no description once the store has answered, the piece in a line, as on the site.
    private var blocks: [DescriptionBlock] {
        let own = descriptionBlocks(detail?.descriptionHtml ?? "")
        if !own.isEmpty || !complete { return own }
        let detailLine = piece.detail.isEmpty ? "" : " \(piece.detail)."
        return [.paragraph("\(piece.designer) \(piece.title).\(detailLine)")]
    }

    /// What the house stands behind (Sam, November 1), then shipping and questions; Email us opens Mail.
    private var note: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Every piece is inspected and photographed in New York before it’s listed.")
                .textStyle(.productNote)
                .foregroundStyle(.ink2)
            Text(shipping)
                .textStyle(.productNote)
                .foregroundStyle(.muted)
                .tint(.ink2)
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    private var shipping: AttributedString {
        var line = AttributedString("Ships from New York City · 14-day returns · Questions? ")
        var link = AttributedString("Email us")
        link.link = URL(string: "mailto:\(Merch.contact.email)")
        link.foregroundColor = .ink2
        link.underlineStyle = .single
        line.append(link)
        return line
    }

    /// Details (only for pieces with written facts or an authentication card) and Shipping & returns, both folded,
    /// under one hairline: the only rule in the column.
    private var folds: some View {
        let details = detail.map(detailsList) ?? []
        return VStack(alignment: .leading, spacing: 0) {
            Rectangle().fill(.line).frame(height: 1)
            if !details.isEmpty {
                Fold(title: "Details", open: $detailsOpen) {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(details, id: \.self) { line in
                            HStack(alignment: .firstTextBaseline, spacing: 0) {
                                Text("•")
                                    .textStyle(.foldList)
                                    .frame(width: 18, alignment: .leading)
                                    .padding(.leading, 4)
                                    .accessibilityHidden(true)
                                Text(line)
                                    .textStyle(.foldList)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .foregroundStyle(.ink2)
                    .padding(.bottom, 16)
                }
            }
            Fold(title: "Shipping & returns", open: $shipOpen) {
                Text(
                    "Ships from New York City: standard shipping $12, express $35. Returns are accepted within 14 days of delivery, with return shipping paid by the buyer."
                )
                .textStyle(.foldText)
                .foregroundStyle(.ink2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 16)
            }
        }
    }
}

/// The price (22pt, 600), then the status in quiet spaced capitals, on one line; the status wraps under the price only
/// when the two don't fit. A pre-owned piece's grade follows Pre-owned in the same type, set off by a hairline instead
/// of the middle dot: "SIZE S · PRE-OWNED | LIKE NEW" (SPEC §10).
private struct PriceLine: View {
    let price: String
    let marks: [StatusMark]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let p = Text(price).textStyle(.productPrice).foregroundStyle(.ink).monospacedDigit()
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                p
                if !marks.isEmpty { status.fixedSize() }
            }
            VStack(alignment: .leading, spacing: 4) {
                p
                if !marks.isEmpty { status.fixedSize(horizontal: false, vertical: true) }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel([price, words].filter { !$0.isEmpty }.joined(separator: ", "))
    }

    /// The marks in words, as a screen reader says them ("Size S · Pre-owned Like new").
    private var words: String {
        marks.map { m in m.grade.map { "\(m.text) \($0.rawValue)" } ?? m.text }.joined(separator: " · ")
    }

    private var status: some View {
        var line = Text(verbatim: "")
        for (i, m) in marks.enumerated() {
            if i > 0 { line = Text("\(line) · ") }
            line = Text("\(line)\(m.text)")
            if let grade = m.grade {
                // A real space, then the hairline .35em after it and .6em before the grade (the site's `.pd-cond`).
                line = Text("\(line) \(hairline)\(grade.rawValue)")
            }
        }
        return line
            .textStyle(.productMarks)
            .foregroundStyle(.muted)
    }

    /// The hairline between Pre-owned and its grade: 1pt of `line-strong` as tall as the type's line, .35em in.
    private var hairline: Text {
        let size = TextStyle.productMarks.scaledSize(at: dynamicTypeSize)
        let font = UIFont(name: Typeface.body(.semibold).postScriptName, size: size) ?? .systemFont(ofSize: size)
        let left = (0.35 * size).rounded()
        let box = CGSize(width: left + 1 + 0.6 * size, height: ceil(font.ascender - font.descender))
        let image = UIGraphicsImageRenderer(size: box).image { context in
            UIColor(Color.lineStrong).setFill()
            context.fill(CGRect(x: left, y: 0, width: 1, height: box.height))
        }
        return Text(Image(uiImage: image).renderingMode(.original)).baselineOffset(font.descender)
    }
}

// MARK: - The description

/// The description, right under the price (SPEC §10): 15pt with the site's line height, in `ink-3`. It opens at three
/// lines with an ellipsis, the paragraphs running on as one flow; an underlined Read more, only when there's more,
/// shows the whole text with its paragraph breaks and becomes Read less. Read less keeps your place: if the shorter text
/// would take the link up under the header, the page moves with it.
private struct ProductDescription: View {
    let blocks: [DescriptionBlock]
    let scroll: PageScroll

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var open = false
    @State private var cut: CGFloat = 0
    @State private var whole: CGFloat = 0
    @State private var openHeight: CGFloat = 0
    @State private var top: CGFloat = 0

    private var more: Bool { open || whole > cut + 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if blocks.isEmpty {
                EmptyView()
            } else if open {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                        blockView(block)
                    }
                }
                .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { openHeight = $0 }
                .transition(.opacity.animation(Motion.ease(0.45)))
            } else {
                let flow = descriptionFlow(blocks)
                Text(flow)
                    .textStyle(.productDescription)
                    .foregroundStyle(.ink3)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { cut = $0 }
                    .background(alignment: .top) {
                        Text(flow)
                            .textStyle(.productDescription)
                            .fixedSize(horizontal: false, vertical: true)
                            .hidden()
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { whole = $0 }
                            .accessibilityHidden(true)
                    }
            }
            if more {
                Button(action: toggle) {
                    Text(open ? "Read less" : "Read more")
                        .textStyle(.readMore)
                        .foregroundStyle(.ink)
                        .lineUnder(true, offset: 5)
                        .frame(minHeight: 44)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.bottom, -10)
                .accessibilityValue(open ? "Expanded" : "Collapsed")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(PageSpace.name)).minY } action: { top = $0 }
    }

    @ViewBuilder private func blockView(_ block: DescriptionBlock) -> some View {
        switch block {
        case .paragraph(let text):
            Text(text)
                .textStyle(.productDescription)
                .foregroundStyle(.ink3)
                .fixedSize(horizontal: false, vertical: true)
        case .item(let text):
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("•")
                    .textStyle(.productDescription)
                    .foregroundStyle(.ink3)
                    .frame(width: 18, alignment: .leading)
                    .padding(.leading, 4)
                    .accessibilityHidden(true)
                Text(text)
                    .textStyle(.productDescription)
                    .foregroundStyle(.ink3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func toggle() {
        if open {
            // Where Read less will be once the text is three lines again: under the header, the page follows it.
            let shrink = openHeight - cut
            let linkOnScreen = top + cut - scroll.offset
            open = false
            if shrink > 0, linkOnScreen < SiteHeader.pieceRowHeight { scroll.jump(by: -shrink) }
        } else {
            open = true
        }
    }
}

// MARK: - Add to Bag and the heart

/// Add to Bag fills the row (square: content is square), the heart a 52pt square beside it, which pops when saved. A
/// piece in several sizes asks for one first, above the row (sizes that sold drop out). Once it's in the bag the
/// button says so and leads there. A sold piece says so plainly. Adding opens the bag's sheet with the piece; if
/// Shopify refuses it, or it's missing from the cart's answer, the row says "That piece has just sold." (APP-SPEC §3.7).
private struct BagRow: View {
    let piece: Piece
    let detail: ProductDetail?

    @Environment(AppState.self) private var app
    @Environment(Bag.self) private var bag
    @Environment(SavedPieces.self) private var saved
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var pick: String?
    /// Counts each save, for the heart's pop.
    @State private var pops = 0

    private var variants: [Variant] { detail?.variants ?? [] }
    private var available: [Variant] { variants.filter(\.available) }
    private var sized: Bool { variants.count > 1 }
    /// The size to add: the one picked, or the only one still for sale.
    private var variant: Variant? {
        if let pick, let v = available.first(where: { $0.id == pick }) { return v }
        return available.count == 1 ? available.first : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if detail != nil && available.isEmpty {
                HStack(spacing: 10) {
                    bigButton("Sold", style: .off) {}
                        .disabled(true)
                    heart
                }
                Text("This piece has sold. Similar pieces are below.")
                    .textStyle(.productMessage)
                    .foregroundStyle(.ink2)
            } else {
                if sized { sizes }
                HStack(spacing: 10) {
                    if let variant, bag.contains(variant: variant.id) {
                        bigButton("In your bag · View Bag", style: .outline) { app.tab = .bag }
                    } else {
                        let busy = variant != nil && bag.adding == variant?.id
                        // (Until a size is picked, the button is the site's disabled one: stone, muted.)
                        bigButton(
                            variant == nil && detail != nil ? "Choose a size" : busy ? "Adding…" : "Add to Bag",
                            style: variant == nil ? .off : .solid
                        ) {
                            if let variant { Task { await bag.add(variantId: variant.id) } }
                        }
                        .disabled(variant == nil || bag.adding != nil)
                    }
                    heart
                }
                if let variant, let problem = bag.problems[variant.id] {
                    Text(problem)
                        .textStyle(.productMessage)
                        .foregroundStyle(.ink2)
                }
            }
        }
    }

    // MARK: The sizes

    /// "Size", then a chip for each size still for sale (the site's `.fchip`: 34pt round, 14pt; ink when picked).
    private var sizes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Size")
                .textStyle(.sectionLabel)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            ChipFlow(spacing: 6) {
                ForEach(available, id: \.id) { v in
                    let on = v.id == pick
                    Button { pick = v.id } label: {
                        Text(v.size ?? "")
                            .textStyle(.sizeChip)
                            .foregroundStyle(on ? Color.paper : Color.ink)
                            .padding(.horizontal, 12)
                            .frame(height: 34)
                            .background(Capsule().fill(on ? Color.ink : Color.paper))
                            .overlay(Capsule().strokeBorder(on ? Color.ink : Color.ink.opacity(0.14), lineWidth: 1))
                            .contentShape(.capsule)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Size \(v.size ?? "")")
                    .accessibilityAddTraits(on ? [.isSelected] : [])
                    .animation(.easeOut(duration: 0.2), value: on)
                }
            }
        }
    }

    // MARK: The buttons

    /// Solid ink (Add to Bag), outlined (In your bag), or off: stone and muted (Sold, and Choose a size until one is).
    private enum Look { case solid, outline, off }

    private func bigButton(_ title: String, style: Look, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .textStyle(.bigButton)
                .foregroundStyle(style == .solid ? Color.paper : style == .off ? Color.muted : Color.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(style == .solid ? Color.ink : style == .off ? Color.stone : Color.paper)
                .overlay { Rectangle().strokeBorder(style == .off ? Color.lineStrong : Color.ink, lineWidth: 1) }
                .contentShape(.rect)
        }
        .buttonStyle(Dim())
    }

    /// A 52pt square, the heart (22pt, the 1.6 stroke) filled when saved; it pops as it's saved.
    private var heart: some View {
        let on = saved.contains(piece)
        return Button {
            saved.toggle(piece)
            if saved.contains(piece) && !reduceMotion { pops += 1 }
        } label: {
            ZStack {
                HeartShape().fill(on ? Color.ink : Color.clear)
                HeartShape().stroke(.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 22, height: 22)
            .keyframeAnimator(initialValue: 1.0, trigger: pops) { content, scale in
                content.scaleEffect(scale)
            } keyframes: { _ in
                CubicKeyframe(1.22, duration: 0.14)
                CubicKeyframe(0.94, duration: 0.14)
                CubicKeyframe(1.0, duration: 0.2)
            }
            .frame(width: 52, height: 52)
            .overlay { Rectangle().strokeBorder(Color.lineStrong, lineWidth: 1) }
            .background(.paper)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Save")
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: on)
    }
}

/// Pressing a square button: it dims a touch.
private struct Dim: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed && isEnabled ? 0.82 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

/// Chips in rows that wrap, `spacing` apart both ways.
private struct ChipFlow: SwiftUI.Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews)
        let height = rows.last.map { $0.y + $0.height } ?? 0
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        for row in arrange(width: bounds.width, subviews) {
            for (i, x) in zip(row.items, row.xs) {
                subviews[i].place(at: CGPoint(x: bounds.minX + x, y: bounds.minY + row.y), proposal: .unspecified)
            }
        }
    }

    private struct Row {
        var items: [Int] = []
        var xs: [CGFloat] = []
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, _ subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if !row.items.isEmpty, row.width + spacing + size.width > width {
                rows.append(row)
                row = Row(y: row.y + row.height + spacing)
            }
            row.xs.append(row.items.isEmpty ? 0 : row.width + spacing)
            row.width = (row.items.isEmpty ? 0 : row.width + spacing) + size.width
            row.items.append(i)
            row.height = max(row.height, size.height)
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}

// MARK: - A fold

/// A folded section (SPEC §10): its title in 12pt spaced capitals on a 54pt row with a plus that turns to a minus; what
/// it holds rises in under it. VoiceOver hears whether it's open.
private struct Fold<Content: View>: View {
    let title: String
    @Binding var open: Bool
    @ViewBuilder var content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(reduceMotion ? .easeOut(duration: 0.2) : Motion.easeOut(0.45)) { open.toggle() }
            } label: {
                HStack {
                    Text(title)
                        .textStyle(.sectionLabel)
                        .foregroundStyle(.ink)
                    Spacer(minLength: 12)
                    PlusMinus(open: open)
                        .frame(width: 14, height: 14)
                }
                .frame(height: 54)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityValue(open ? "Expanded" : "Collapsed")
            if open {
                content()
                    .transition(reduceMotion ? .opacity : .opacity.combined(with: .offset(y: 8)))
            }
        }
    }
}

/// The fold's plus; open, its upright turns away and leaves a minus (the site's `.v` line: rotate 90°, scale to 0).
private struct PlusMinus: View {
    let open: Bool

    var body: some View {
        ZStack {
            Capsule().fill(.ink).frame(width: 14 * 14 / 24, height: 1.8 * 14 / 24)
            Capsule().fill(.ink).frame(width: 1.8 * 14 / 24, height: 14 * 14 / 24)
                .rotationEffect(.degrees(open ? 90 : 0))
                .scaleEffect(x: 1, y: open ? 0 : 1)
        }
        .animation(Motion.easeOut(0.35), value: open)
        .accessibilityHidden(true)
    }
}
