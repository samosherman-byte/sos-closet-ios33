import SwiftUI
import UIKit

/// A piece's card (APP-SPEC §3.3; SPEC §7, Card text, Photo size standard, Every photo on its card): its photo on its
/// tile, then the designer, the name and price · size, and a heart on the photo's top right. No glass, shadow or
/// effect on the photo or the card (SPEC §1.8), and the photo files are never changed: the card only places them.
struct PieceCard: View {
    let piece: Piece
    /// The card's width (half the window, less the 3pt between: the grid runs edge to edge).
    let width: CGFloat
    /// The row's shared tile height (`CardPhotoFit.rowTileHeight`).
    let tileHeight: CGFloat
    /// The photo size standard's `--fk` (1 on phones).
    var factor: Double = 1
    /// In a small department's case: the piece's story line under its name, and the name not cut short.
    var story = false
    /// The piece leading a case on a row of its own: its words keep the margin on both sides.
    var lead = false

    @Environment(AppState.self) private var app
    @Environment(SavedPieces.self) private var saved
    @Environment(\.displayScale) private var displayScale
    @Environment(\.pieceZoom) private var zoom
    @Environment(\.zoomContext) private var context
    @State private var near = false
    /// The photo the card is showing: its piece's page opens on it (SPEC §5).
    @State private var photo = 0

    /// The card's photo, which its piece's page zooms out of (unique on the page: the same piece can have a card in a
    /// department and in a piece's "You may also like").
    private var zoomID: String { context + "|" + piece.id }

    private var sizeLine: String { sizeWords(piece.sizes, range: true) }
    private var price: String { moneyText(piece.price) }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                app.open(piece, photo: photo, zoomID: zoomID)
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    CardPhotos(
                        piece: piece, width: width, tileHeight: tileHeight, factor: factor, near: near, zoomID: zoomID,
                        at: $photo
                    )
                    .zoomSource(zoomID, in: zoom)
                    words
                }
                .contentShape(.rect)
            }
            .buttonStyle(CardPress())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel([piece.designer, piece.title, price, sizeLine].filter { !$0.isEmpty }.joined(separator: ", "))
            .accessibilityHint(story ? (piece.story ?? "") : "")
            heart
        }
        .frame(width: width, alignment: .topLeading)
        // Photos load as their card comes within about a screen of the view, and are let go far away from it (the
        // loader keeps them for coming back).
        .background(alignment: .top) {
            Color.clear
                .frame(height: tileHeight + 1200)
                .offset(y: -600)
                .onScrollVisibilityChange(threshold: 0.01) { near = $0 }
                .allowsHitTesting(false)
                .accessibilityHidden(true)
        }
    }

    // MARK: The words

    /// Designer, name, (story,) price · size: 12pt under the photo, 16pt in from the left and 10pt from the right.
    private var words: some View {
        VStack(alignment: .leading, spacing: 4) {
            FittedDesigner(text: piece.designer, room: width - (lead ? 32 : 26))
            Text(piece.title)
                .textStyle(.cardName)
                .foregroundStyle(.ink2)
                .lineLimit(story ? nil : 2)
                .fixedSize(horizontal: false, vertical: true)
            if story, let line = piece.story, !line.isEmpty {
                Text(line)
                    .textStyle(.cardStory)
                    .foregroundStyle(.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, -2)
            }
            priceLine
                .padding(.top, 3)
        }
        .padding(.top, 12)
        .padding(.leading, 16)
        .padding(.trailing, lead ? 16 : 10)
        .frame(maxWidth: .infinity, minHeight: 96, alignment: .topLeading)
    }

    /// The price (15pt, 500), then the size after a middle dot (13pt, muted), on one line; the size wraps under it only
    /// when the two don't fit.
    private var priceLine: some View {
        let p = Text(price).textStyle(.cardPrice).foregroundStyle(.ink).monospacedDigit()
        let z = Text("· " + sizeLine).textStyle(.cardSize).foregroundStyle(.muted).lineLimit(1)
        return ViewThatFits(in: .horizontal) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                p
                if !sizeLine.isEmpty { z }
            }
            .fixedSize()
            VStack(alignment: .leading, spacing: 2) {
                p
                if !sizeLine.isEmpty { z }
            }
        }
    }

    // MARK: The heart

    /// A 44pt button on the photo's top right, 6pt from the top and the side; the outline fills when saved.
    private var heart: some View {
        let on = saved.contains(piece)
        return Button {
            saved.toggle(piece)
        } label: {
            ZStack {
                HeartShape().fill(on ? Color.ink : Color.clear)
                HeartShape().stroke(.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round, lineJoin: .round))
            }
            .frame(width: 20, height: 20)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .padding(.top, 6)
        .padding(.trailing, 6)
        .accessibilityLabel("Save")
        .accessibilityAddTraits(on ? [.isSelected] : [])
        .sensoryFeedback(.selection, trigger: on)
    }
}

/// The card's photo dips under the finger (SPEC §5: to 97.5%, 250ms ease-out), so the tap feels physical. Not with
/// Reduce Motion.
private struct CardPress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .environment(\.cardPressed, configuration.isPressed && !reduceMotion)
    }
}

extension EnvironmentValues {
    @Entry var cardPressed = false
}

// MARK: - The photos

/// The card's photo tile: the cover by the photo size standard, and, for a piece with more than one look photo, a
/// sideways track through them, one photo per swipe, with quiet dots only while sliding and 1.2s after (SPEC §7).
private struct CardPhotos: View {
    let piece: Piece
    let width: CGFloat
    let tileHeight: CGFloat
    let factor: Double
    let near: Bool
    let zoomID: String
    /// The photo in view.
    @Binding var at: Int

    @Environment(AppState.self) private var app
    @Environment(\.cardPressed) private var pressed
    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var track = ScrollPosition(idType: Int.self)
    @State private var sliding = false
    @State private var settle: Task<Void, Never>?

    /// The photos the card shows: the cover, then the piece's other look photos (never labels, hangtags or model
    /// photos; proof photos wait for the product page).
    private var photos: [CardPhoto] {
        guard let cover = piece.image else { return [] }
        return [CardPhoto(url: cover.url, width: cover.width)] + (piece.morePhotos ?? [])
    }

    /// Pixels to decode a photo at: the card's width on this screen.
    private var pixels: Int { Int((width * 1.25 * displayScale).rounded(.up)) }

    private func url(_ photo: CardPhoto) -> URL {
        sizedImageURL(photo.url, width: imageWidth(forPixels: Double(width * displayScale), max: photo.width))
    }

    var body: some View {
        let list = photos
        ZStack(alignment: .bottom) {
            if list.count > 1 {
                ScrollView(.horizontal) {
                    HStack(spacing: 0) {
                        ForEach(Array(list.enumerated()), id: \.offset) { k, photo in
                            slide(k, photo)
                                .frame(width: width, height: tileHeight)
                                .clipped()
                                .id(k)
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollIndicators(.hidden)
                .scrollTargetBehavior(.paging)
                .scrollPosition($track)
                // Coming back from its piece's page, the card turns to the photo the page was showing, so the page
                // zooms back into that photo (SPEC §5).
                .onChange(of: app.turnBack) { _, back in
                    guard let back, back.zoomID == zoomID, back.photo != at, list.indices.contains(back.photo) else { return }
                    var now = Transaction()
                    now.disablesAnimations = true
                    withTransaction(now) { track.scrollTo(id: back.photo) }
                    at = back.photo
                }
                .onScrollGeometryChange(for: Int.self) { g in
                    Int((g.contentOffset.x / max(1, g.containerSize.width)).rounded())
                } action: { _, k in
                    at = k
                }
                .onScrollPhaseChange { _, phase in
                    slidingChanged(phase.isScrolling)
                    if phase.isScrolling { PhotoLoader.shared.prefetch(list.dropFirst().map(url), maxPixels: pixels) }
                }
                dots(list.count)
            } else if let only = list.first {
                cover(only)
            }
        }
        .frame(width: width, height: tileHeight)
        .background(piece.fit != nil || list.isEmpty ? Color.paper : Color.stone)
        .clipped()
        .scaleEffect(pressed ? 0.975 : 1)
        .animation(.timingCurve(0.16, 1, 0.3, 1, duration: 0.25), value: pressed)
        .accessibilityHidden(true)
    }

    @ViewBuilder private func slide(_ k: Int, _ photo: CardPhoto) -> some View {
        if k == 0 {
            cover(photo)
        } else {
            // The others fill their 4:5 frame as photographed, cropped from the middle, and a row's trimmed top never
            // cuts them off: the frame is as tall as the tile, centered on white.
            LoadedPhoto(url: url(photo), maxPixels: pixels, active: near && abs(k - at) <= 1) { image in
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: tileHeight * 0.8, height: tileHeight)
                    .clipped()
            }
            .frame(width: width, height: tileHeight)
            .background(.paper)
        }
    }

    /// The cover fills the card's 4:5 frame, cropped from the middle; with the size standard's numbers it's scaled
    /// about its centre and moved down by a share of its own height, on white. The frame hangs from the tile's bottom,
    /// so a row's trimmed top clips only white.
    private func cover(_ photo: CardPhoto) -> some View {
        let full = width * 1.25
        let fit = CardPhotoFit.transform(piece.fit, factor: factor)
        return LoadedPhoto(url: url(photo), maxPixels: pixels, active: near) { image in
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: width, height: full)
                .clipped()
                .scaleEffect(fit?.scale ?? 1)
                .offset(y: full * (fit?.drop ?? 0))
        }
        .frame(width: width, height: full)
        .frame(width: width, height: tileHeight, alignment: .bottom)
        .accessibilityLabel(piece.image?.alt ?? "")
    }

    /// 5pt dots, 5pt apart, 8pt above the photo's bottom: the current one ink, the rest `line-strong`, each with a faint
    /// white ring. Only while sliding, and 1.2s after.
    private func dots(_ n: Int) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<n, id: \.self) { k in
                Circle()
                    .fill(k == at ? Color.ink : Color.lineStrong)
                    .frame(width: 5, height: 5)
                    .overlay(Circle().stroke(.white.opacity(0.7), lineWidth: 1).padding(-0.5))
            }
        }
        .padding(.bottom, 8)
        .opacity(sliding ? 1 : 0)
        .animation(Motion.ease(0.3), value: sliding)
        .animation(Motion.ease(0.3), value: at)
        .allowsHitTesting(false)
    }

    private func slidingChanged(_ now: Bool) {
        settle?.cancel()
        if now {
            sliding = true
        } else {
            settle = Task {
                try? await Task.sleep(for: .milliseconds(1200))
                if !Task.isCancelled { sliding = false }
            }
        }
    }
}

// MARK: - Rows of cards

/// Pieces two across, edge to edge (3pt between), rows 32pt apart; the cards of a row share one tile height (SPEC §7).
struct PieceGrid: View {
    let pieces: [Piece]
    /// The page's width.
    let width: CGFloat

    var body: some View {
        let card = (width - 3) / 2
        let factor = CardPhotoFit.factor(forWindowWidth: width)
        VStack(alignment: .leading, spacing: 32) {
            ForEach(Browse.rows(pieces), id: \.first!.id) { row in
                let tile = CardPhotoFit.rowTileHeight(row, width: card, factor: factor)
                HStack(alignment: .top, spacing: 3) {
                    ForEach(row) { piece in
                        PieceCard(piece: piece, width: card, tileHeight: tile, factor: factor)
                    }
                }
            }
        }
    }
}

// MARK: - The designer's line

/// The designer in Tenor Sans spaced capitals (13pt on a 17pt line), on one line, stepping down just enough to fit
/// its card (never below 11pt); past that it takes two lines (SPEC §7; the site's `fitBrand`).
struct FittedDesigner: View {
    let text: String
    /// The room it has: the card's width less its margins.
    let room: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let (style, lines) = fitted
        Text(text)
            .textStyle(style)
            .foregroundStyle(.ink)
            .lineLimit(lines)
            .fixedSize(horizontal: false, vertical: true)
    }

    /// The style it fits at, and how many lines it may take.
    private var fitted: (TextStyle, Int) {
        let base = TextStyle.cardDesigner
        let size = base.scaledSize(at: dynamicTypeSize)
        // (SwiftUI's tracking also follows the last letter, and the line needs a hair to spare.)
        let width = Self.width(of: text, size: size, tracking: base.tracking) + base.tracking * size + 1
        guard width > room, width > 0 else { return (base, 1) }
        let to = (13 * room / width * 4).rounded(.down) / 4
        var style = base
        style.size = max(11, to)
        style.lineHeight = 17 / style.size
        return (style, to >= 11 ? 1 : 2)
    }

    /// The line's width in Tenor Sans capitals at `size`, with its letter spacing (the site measures `scrollWidth`).
    static func width(of text: String, size: CGFloat, tracking: CGFloat) -> CGFloat {
        guard let font = UIFont(name: Typeface.display.postScriptName, size: size) else { return 0 }
        let s = NSAttributedString(string: text.uppercased(), attributes: [.font: font, .kern: tracking * size])
        return ceil(s.size().width)
    }
}

// MARK: - The heart

/// The site's heart (its 24-unit `I_HEART` path), drawn at the frame's size.
nonisolated struct HeartShape: Shape {
    func path(in rect: CGRect) -> Path {
        let k = rect.width / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * k, y: rect.minY + y * k) }
        var path = Path()
        path.move(to: p(12, 20.2))
        path.addCurve(to: p(2.8, 9.2), control1: p(9, 18), control2: p(2.8, 13.9))
        path.addCurve(to: p(7.3, 4.6), control1: p(2.8, 6.6), control2: p(4.8, 4.6))
        path.addCurve(to: p(12, 7.5), control1: p(9.2, 4.6), control2: p(10.7, 5.7))
        path.addCurve(to: p(16.7, 4.6), control1: p(13.3, 5.7), control2: p(14.8, 4.6))
        path.addCurve(to: p(21.2, 9.2), control1: p(19.2, 4.6), control2: p(21.2, 6.6))
        path.addCurve(to: p(12, 20.2), control1: p(21.2, 13.9), control2: p(15, 18))
        path.closeSubpath()
        return path
    }
}
