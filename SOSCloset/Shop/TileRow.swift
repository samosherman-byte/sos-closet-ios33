import SwiftUI
import UIKit

/// The cutout tiles (SPEC §7; APP-SPEC §3.2), read once from the app's SiteAssets/tiles/ (copied unchanged from the
/// site's public/tiles/). A tile shows its file whole, bottom-aligned, and is never nudged.
@MainActor enum TileImages {
    private static var cache: [String: UIImage] = [:]

    static func image(_ dept: Dept, _ category: String) -> UIImage? {
        guard let tile = Merch.catTile[dept]?[category] else { return nil }
        return image(named: tile)
    }

    static func image(named tile: String) -> UIImage? {
        if let hit = cache[tile] { return hit }
        guard let url = Merch.tileURL(tile), let image = UIImage(contentsOfFile: url.path(percentEncoded: false)) else {
            return nil
        }
        cache[tile] = image
        return image
    }
}

/// A department's tile row, the page's table of contents (SPEC §7, §3): one cutout per category, the label under it, no
/// counts and no ALL; all of them across one screen width (54–92pt each, cutouts up to 64 × 50pt, 12pt labels, 11pt
/// under 375pt wide). Tapping a tile glides the page to its section. The tiles float up staggered once, as the page
/// first draws.
struct TileRow: View {
    let dept: Dept
    let categories: [String]
    let width: CGFloat
    let onPick: (String) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    /// The row's height on a phone (14pt above, 6pt below), so the first heading follows about 30pt under the labels.
    static let height: CGFloat = 96

    var body: some View {
        let tile = TileMetrics(count: categories.count, width: width)
        HStack(alignment: .top, spacing: TileMetrics.gap) {
            ForEach(Array(categories.enumerated()), id: \.element) { i, category in
                Button { onPick(category) } label: {
                    VStack(spacing: 8) {
                        TileCutout(image: TileImages.image(dept, category), small: false)
                            .frame(width: min(64, tile.width), height: 50)
                        Text(category)
                            .textStyle(width < Layout.narrowWidth ? .tileLabelNarrow : .tileLabel)
                            .foregroundStyle(.ink)
                            .lineLimit(1)
                            .fixedSize()
                            .frame(height: 16)
                    }
                    .frame(width: tile.width)
                    .contentShape(.rect)
                }
                .buttonStyle(TilePress())
                .accessibilityLabel(category)
                .accessibilityShowsLargeContentViewer { Text(category) }
                .offset(y: shown || reduceMotion ? 0 : 22)
                .opacity(shown ? 1 : 0)
                .animation(
                    reduceMotion ? .easeOut(duration: 0.2) : Motion.easeOut(0.9).delay(Double(i) * 0.07 + 0.06),
                    value: shown)
            }
        }
        .padding(.top, 14)
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: Self.height, alignment: .top)
        // (A table of contents of fixed tiles: it keeps its size, and a long press shows a label large.)
        .dynamicTypeSize(...DynamicTypeSize.large)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Categories")
        .onAppear { shown = true }
    }
}

/// The compact copy of the tile row that hangs under the header on the way back up (SPEC §3, "The cutouts come back
/// with the tabs"): the same cutouts and words, smaller (cutouts 30pt tall, words 11pt), flat white with a bottom
/// hairline and the header's soft shadow; the section in view underlined.
struct CompactTileRow: View {
    let dept: Dept
    let categories: [String]
    let current: String
    let width: CGFloat
    let onPick: (String) -> Void

    @Namespace private var underline
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    static let height: CGFloat = 62

    var body: some View {
        let tile = TileMetrics(count: categories.count, width: width)
        HStack(alignment: .top, spacing: TileMetrics.gap) {
            ForEach(categories, id: \.self) { category in
                let on = category == current
                Button { onPick(category) } label: {
                    VStack(spacing: 4) {
                        TileCutout(image: TileImages.image(dept, category), small: true)
                            .frame(width: 40, height: 30)
                        Text(category)
                            .textStyle(on ? .compactTileLabelOn : .compactTileLabel)
                            .foregroundStyle(.ink)
                            .lineLimit(1)
                            .fixedSize()
                            .frame(height: 15)
                            .overlay(alignment: .bottom) {
                                if on {
                                    Rectangle().fill(.ink).frame(height: 1)
                                        .matchedGeometryEffect(id: "line", in: underline)
                                        .offset(y: 4)
                                }
                            }
                    }
                    .frame(width: tile.width)
                    .contentShape(.rect)
                }
                .buttonStyle(TilePress())
                .accessibilityLabel(category)
                .accessibilityAddTraits(on ? [.isSelected] : [])
                .accessibilityShowsLargeContentViewer { Text(category) }
            }
        }
        // (Reduce Motion: the underline moves to its section at once, without sliding.)
        .animation(reduceMotion ? nil : Motion.easeOut(0.45), value: current)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .top)
        .frame(height: Self.height, alignment: .top)
        .background(.paper)
        .overlay(alignment: .bottom) { Rectangle().fill(.line).frame(height: 1) }
        // The header's soft shadow (`0 10px 30px -24px` ink at 45%): a faint band just under the hairline.
        .background(alignment: .bottom) {
            LinearGradient(colors: [Color.ink.opacity(0.07), Color.ink.opacity(0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 10)
                .offset(y: 10)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Categories")
    }
}

/// How wide each tile is: they share one screen width, 54 to 92pt each, 4pt apart, inside the 16pt margins.
private struct TileMetrics {
    static let gap: CGFloat = 4
    let width: CGFloat

    init(count: Int, width page: CGFloat) {
        let n = CGFloat(max(1, count))
        let room = page - 2 * Layout.gutter(forWidth: page) - Self.gap * (n - 1)
        width = min(92, max(54, (room / n).rounded(.down)))
    }
}

/// A cutout shown whole on its 4:3 canvas, bottom-aligned, with its one soft shadow (`--e-obj`: 0 9 7 ink at 12% and
/// 0 2 2 at 7%; in the directory and the compact row the lighter `--e-obj-sm`, 0 3 3 at 12%). SwiftUI's shadow radius
/// is about half of CSS's blur.
struct TileCutout: View {
    let image: UIImage?
    let small: Bool

    var body: some View {
        if let image {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .shadow(color: Color.ink.opacity(0.12), radius: small ? 1.5 : 3.5, y: small ? 3 : 9)
                .shadow(color: Color.ink.opacity(small ? 0 : 0.07), radius: 1, y: 2)
                .accessibilityHidden(true)
        } else {
            Color.clear
        }
    }
}

/// Pressing a tile: a slight scale (SPEC §7). Not with Reduce Motion.
private struct TilePress: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1)
            .animation(Motion.easeOut(0.35), value: configuration.isPressed)
    }
}
