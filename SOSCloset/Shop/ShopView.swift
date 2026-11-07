import SwiftUI

/// Shop: Shop All and the three departments, one page each, under the header with their tab underlined (APP-SPEC
/// §3.2, §7). No title (the selected tab is their name), no intro, no counts. Moving between them pushes the new page in
/// from its side of the map (SPEC §1.1, §5), under the same header.
struct ShopView: View {
    @Environment(AppState.self) private var app
    @Environment(Closet.self) private var closet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let scroll = app.shopScroll
        let model = Browse.page(app.place, pieces: closet.pieces)
        PageFrame(
            current: app.place,
            scroll: scroll,
            placeName: app.place.label(narrow: false),
            placeHasSections: !model.isCase,
            compact: model.dept.flatMap { dept in
                model.tiles.isEmpty
                    ? nil
                    : CompactTiles(dept: dept, categories: model.tiles) { category in
                        scroll.glide(toSection: category, reduceMotion: reduceMotion)
                    }
            }
        ) { width in
            ZStack(alignment: .top) {
                ShopPage(model: model, scroll: scroll, width: width)
                    .id(ObjectIdentifier(scroll))
                    .transition(pageTransition)
            }
            .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.push(0.52), value: ObjectIdentifier(scroll))
            .clipped()
        }
    }

    /// Along the map: a page further right comes in from the right and the old one leaves to the left, and back the
    /// other way. Reduce Motion: a fade.
    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return app.direction > 0
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }
}

/// One Shop page in its own scroll view: a department's tile row, then its sections (or Shop All's, or a small
/// department's case).
private struct ShopPage: View {
    let model: ShopPageModel
    let scroll: PageScroll
    let width: CGFloat

    @Environment(AppState.self) private var app
    @Environment(Closet.self) private var closet
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Two across, edge to edge, 3pt between (SPEC §7).
    private var cardWidth: CGFloat { (width - 3) / 2 }
    private var factor: Double { CardPhotoFit.factor(forWindowWidth: width) }

    var body: some View {
        PageScrollView(scroll: scroll, refresh: { await closet.refresh() }, topRoom: SiteHeader.tabRowHeight) {
            VStack(alignment: .leading, spacing: 0) {
                if let dept = model.dept, !model.tiles.isEmpty {
                    TileRow(dept: dept, categories: model.tiles, width: width) { category in
                        scroll.glide(toSection: category, reduceMotion: reduceMotion)
                    }
                }
                // The filter line's room when it has no tags (8pt): Search comes in phase 2.
                Color.clear.frame(height: 8)
                if model.isCase {
                    caseOf(model.casePieces)
                } else {
                    sections
                }
                status
            }
            .padding(.bottom, 56)
            .frame(width: width, alignment: .topLeading)
        }
        .onAppear {
            scroll.threshold = model.tiles.isEmpty ? 160 : 140
            scroll.outline = model.outline
        }
        .onChange(of: model.outline.map(\.section)) { scroll.outline = model.outline }
    }

    // MARK: Sections

    /// Each section: its heading (while there's more than one), then its pieces, by type in a department's category.
    private var sections: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(model.sections.enumerated()), id: \.element.id) { i, section in
                VStack(alignment: .leading, spacing: 0) {
                    if model.showsSectionHeadings {
                        SectionHeading(name: section.name, opens: opens(section))
                    }
                    if section.showsTypeHeadings {
                        ForEach(Array(section.types.enumerated()), id: \.element.id) { k, group in
                            TypeHeading(name: group.name)
                                .pageAnchor(PageScroll.typeKey(section.name, group.name), in: scroll)
                                .padding(.top, k == 0 ? 6 : 36)
                            grid(group.pieces)
                                .padding(.top, 6)
                        }
                    } else {
                        grid(section.pieces)
                            .padding(.top, model.showsSectionHeadings ? 16 : 8)
                    }
                }
                .pageAnchor(PageScroll.sectionKey(section.name), in: scroll)
                .padding(.top, i == 0 ? 0 : 56)
            }
        }
    }

    /// Shop All's department headings open that department (sliding in from its side, like the tabs). The Latest's
    /// "See all ›" waits for New Arrivals, and a department's headings don't narrow in phase 1 (APP-SPEC §2).
    private func opens(_ section: BrowseSection) -> (() -> Void)? {
        guard case .dept(let dept) = section.kind else { return nil }
        return { app.open(ShopPlace(dept)) }
    }

    /// Rows of two, 32pt apart; the cards of a row share one tile height.
    private func grid(_ pieces: [Piece]) -> some View {
        VStack(alignment: .leading, spacing: 32) {
            ForEach(Browse.rows(pieces), id: \.first!.id) { row in
                let tile = CardPhotoFit.rowTileHeight(row, width: cardWidth, factor: factor)
                HStack(alignment: .top, spacing: 3) {
                    ForEach(row) { piece in
                        PieceCard(piece: piece, width: cardWidth, tileHeight: tile, factor: factor) { app.open(piece) }
                    }
                }
            }
        }
    }

    // MARK: The case

    /// A small department's case (SPEC §7): two across, edge to edge, each piece with its story line; with an odd
    /// number the first leads on a row of its own, its photo the width of the screen. Its tiles are whole (a row's trim
    /// is the grid's).
    private func caseOf(_ pieces: [Piece]) -> some View {
        let (lead, rows) = Browse.caseLayout(pieces)
        return VStack(alignment: .leading, spacing: 40) {
            if let lead {
                PieceCard(piece: lead, width: width, tileHeight: width * 1.25, factor: factor, story: true, lead: true) {
                    app.open(lead)
                }
            }
            ForEach(rows, id: \.first!.id) { row in
                HStack(alignment: .top, spacing: 3) {
                    ForEach(row) { piece in
                        PieceCard(
                            piece: piece, width: cardWidth, tileHeight: cardWidth * 1.25, factor: factor, story: true
                        ) { app.open(piece) }
                    }
                }
            }
        }
        .padding(.top, 8)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pieces")
    }

    // MARK: Loading

    /// While the closet loads, nothing (the page's white); if it can't, why, plainly.
    @ViewBuilder private var status: some View {
        if case .failed(let message) = closet.state, model.isEmpty {
            Text(message)
                .textStyle(.noteText)
                .foregroundStyle(.ink2)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 24)
                .padding(.top, 48)
        }
    }
}

/// A section heading (SPEC §7): the display face, uppercase, letter-spaced, 15pt, with a hairline running to the
/// right; not sticky. On Shop All a department's heading is the way in, with a small chevron.
private struct SectionHeading: View {
    let name: String
    let opens: (() -> Void)?

    var body: some View {
        let words = HStack(spacing: 18) {
            HStack(spacing: 6) {
                Text(name)
                    .textStyle(.categoryHeading)
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                    .fixedSize()
                if opens != nil {
                    Polyline(box: CGSize(width: 7, height: 12), points: [(1, 1), (6, 6), (1, 11)])
                        .stroke(.muted, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 7, height: 12)
                }
            }
            Rectangle().fill(.line).frame(height: 1).frame(minWidth: 24)
        }
        .frame(minHeight: 44)
        .padding(.horizontal, 16)
        .contentShape(.rect)

        if let opens {
            Button(action: opens) { words }
                .buttonStyle(.plain)
                .accessibilityLabel(name)
                .accessibilityAddTraits(.isHeader)
        } else {
            words
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(name)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// A type heading inside a category (SPEC §7): 12.5pt semibold uppercase, letter-spaced, in grey ink, no rule, 36pt
/// apart. A plain heading in phase 1 (it narrows with a tag once Search exists), so no chevron.
private struct TypeHeading: View {
    let name: String

    var body: some View {
        Text(name)
            .textStyle(.typeHeading)
            .foregroundStyle(.ink2)
            .frame(minHeight: 40)
            .padding(.horizontal, 16)
            .accessibilityAddTraits(.isHeader)
    }
}
