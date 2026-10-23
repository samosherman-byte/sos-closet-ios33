import SwiftUI
import UIKit

/// The first screen for now (the setup step): the fonts, colors and type styles from SPEC §12, and what the app was
/// built with, to check on a small and a large iPhone. The navigation (branch nav/directions) replaces it.
struct SetupCheckView: View {
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    logo(width: width)
                    section("This build") { status(width: width, height: geometry.size.height) }
                    section("Tiles (from the site, unchanged)") { tiles }
                    section("Type") { typeSamples }
                    section("Colors") { colors }
                }
                .padding(.horizontal, Layout.gutter(forWidth: width))
                .padding(.vertical, 24)
            }
        }
        .background(.paper)
    }

    private func logo(width: CGFloat) -> some View {
        let style: TextStyle = width < Layout.narrowWidth ? .logoNarrow : width <= 420 ? .logoPhone : .logo
        return Text("SOS Closet")
            .textStyle(style)
            .foregroundStyle(.ink)
            .frame(maxWidth: .infinity)
            .accessibilityAddTraits(.isHeader)
    }

    private func section(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .textStyle(.sectionLabel)
                .foregroundStyle(.muted)
                .accessibilityAddTraits(.isHeader)
            content()
        }
    }

    // MARK: This build

    private func status(width: CGFloat, height: CGFloat) -> some View {
        let missing = Typeface.missing()
        return VStack(alignment: .leading, spacing: 8) {
            row("Store", storeLine)
            row("Fonts", missing.isEmpty ? "Tenor Sans and Hanken Grotesk 400–700 all load" : "Missing: " + missing.map(\.postScriptName).joined(separator: ", "))
            row("Site photos", siteAssetsLine)
            row("Window", "\(Int(width.rounded())) × \(Int(height.rounded())) pt")
        }
    }

    private var storeLine: String {
        switch StoreConfig.source {
        case .sample:
            guard let url = StoreConfig.sampleStoreURL else { return "Sample store: missing (run tools/sync-sample-store.sh)" }
            let photos = (try? FileManager.default.contentsOfDirectory(atPath: url.appending(path: "prototype/img").path()).count) ?? 0
            return "Sample store, \(photos) photos (\(source(in: url)))"
        case .shopify:
            return StoreConfig.endpoint == nil ? "Sam's store: not connected yet (Config/Secrets.xcconfig)" : "Sam's store: \(StoreConfig.storeDomain)"
        }
    }

    private var siteAssetsLine: String {
        guard let url = StoreConfig.siteAssetsURL else { return "Missing (run tools/sync-sample-store.sh)" }
        let count = { (folder: String) in (try? FileManager.default.contentsOfDirectory(atPath: url.appending(path: folder).path()).count) ?? 0 }
        return "\(count("tiles")) tiles, \(count("home")) home photos"
    }

    /// The site's commit the copies came from, as tools/sync-sample-store.sh noted it.
    private func source(in folder: URL) -> String {
        guard let note = try? String(contentsOf: folder.appending(path: "SOURCE.txt"), encoding: .utf8),
              let commit = note.split(separator: " ").drop(while: { $0 != "at" }).dropFirst().first
        else { return "site commit unknown" }
        return "site \(commit)"
    }

    private func row(_ label: String, _ value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .textStyle(.cardSize)
                .foregroundStyle(.muted)
                .frame(width: 84, alignment: .leading)
            Text(value)
                .textStyle(.cardName)
                .foregroundStyle(.ink2)
        }
        .accessibilityElement(children: .combine)
    }

    // MARK: Type

    private var typeSamples: some View {
        VStack(alignment: .leading, spacing: 22) {
            sample("Category heading · Tenor Sans 15, .16em") {
                HStack(spacing: 14) {
                    Text("Handbags").textStyle(.categoryHeading).foregroundStyle(.ink)
                    Rectangle().fill(.line).frame(height: 1)
                }
            }
            sample("Type heading · Hanken 600 12.5, .12em") {
                HStack(spacing: 8) {
                    Text("Top-Handle").textStyle(.typeHeading)
                    Image(systemName: "chevron.right").font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(.ink2)
            }
            sample("Card · designer, name, price · size") {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Gucci").textStyle(.cardDesigner).foregroundStyle(.ink)
                    Text("Jackie 1961 small shoulder bag in green leather").textStyle(.cardName).foregroundStyle(.ink2).lineLimit(2)
                    HStack(spacing: 6) {
                        Text("$2,450").textStyle(.cardPrice).foregroundStyle(.ink)
                        Text("·").textStyle(.cardSize).foregroundStyle(.muted)
                        Text("Size S").textStyle(.cardSize).foregroundStyle(.muted)
                    }
                }
                .frame(maxWidth: 180, alignment: .leading)
            }
            sample("Tabs (phones) · Hanken 500 11, .09em") {
                HStack {
                    ForEach(["Shop All", "Women", "Men", "Jewelry", "Art & Home"], id: \.self) { tab in
                        Text(tab).textStyle(.tab).foregroundStyle(.ink)
                        if tab != "Art & Home" { Spacer(minLength: 0) }
                    }
                }
            }
            sample("Weights · Hanken Grotesk") {
                HStack(spacing: 14) {
                    ForEach([(TextStyle(face: .body(.regular), size: 15), "400"), (TextStyle(face: .body(.medium), size: 15), "500"),
                             (TextStyle(face: .body(.semibold), size: 15), "600"), (TextStyle(face: .body(.bold), size: 15), "700")], id: \.1) { style, label in
                        Text("Aa \(label)").textStyle(style).foregroundStyle(.ink)
                    }
                }
            }
        }
    }

    private func sample(_ caption: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            content()
            Text(caption).textStyle(TextStyle(face: .body(.regular), size: 11)).foregroundStyle(.muted)
        }
    }

    // MARK: Colors

    private let swatches: [(String, Color, String)] = [
        ("paper", .paper, "FFFFFF"), ("ink", .ink, "111111"), ("ink-2", .ink2, "3A3A38"),
        ("muted", .muted, "6E6E6B"), ("stone", .stone, "F3F3F1"), ("line", .line, "E6E6E3"),
        ("line-soft", .lineSoft, "F0F0EE"), ("line-strong", .lineStrong, "C9C9C5"), ("link", .link, "1F4F7A"),
        ("accent", .accent, "B4441B"),
    ]

    private var colors: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 96), spacing: 10, alignment: .leading)], alignment: .leading, spacing: 14) {
            ForEach(swatches, id: \.0) { name, color, hex in
                VStack(alignment: .leading, spacing: 5) {
                    Rectangle().fill(color).frame(height: 36).overlay(Rectangle().strokeBorder(.line, lineWidth: 1))
                    Text(name).textStyle(.cardSize).foregroundStyle(.ink)
                    Text("#\(hex)").textStyle(TextStyle(face: .body(.regular), size: 11)).foregroundStyle(.muted)
                }
                .accessibilityElement(children: .combine)
            }
        }
    }

    // MARK: Tiles

    private var tiles: some View {
        HStack(alignment: .bottom, spacing: 16) {
            ForEach(["women-handbags", "women-clothing", "women-shoes", "women-accessories"], id: \.self) { name in
                if let url = StoreConfig.siteAssetsURL?.appending(path: "tiles/\(name).webp"),
                   let image = UIImage(contentsOfFile: url.path()) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(4 / 3, contentMode: .fit)
                        .frame(width: 64, height: 48, alignment: .bottom)
                        .accessibilityLabel(name)
                } else {
                    Text("missing").textStyle(.cardSize).foregroundStyle(.muted)
                }
            }
        }
    }
}

#Preview {
    SetupCheckView()
}
