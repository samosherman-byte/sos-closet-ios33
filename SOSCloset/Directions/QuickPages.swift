import SwiftUI
import UIKit

// TEMPORARY page contents for the two navigation directions (branch nav/directions): real pieces from the sample
// store, laid out closely enough to judge the navigation over them. The finished pages (the photo size standard,
// type headings, the tile row's entrance, the home page's tiles) come with browse/departments and home.

/// What one place on the map shows, without its scroll view (the pager gives each page its own).
struct QuickPage: View {
    let place: Place
    /// The space the header covers above the first content at the top of the page (direction A's tab row).
    var topPadding: CGFloat = 0

    var body: some View {
        Group {
            switch place {
            case .home: QuickHome()
            case .shopAll: QuickShopAll()
            default: QuickDepartment(place: place)
            }
        }
        .padding(.top, topPadding)
        .padding(.bottom, 40)
    }
}

// MARK: Shop All and the departments

private struct QuickShopAll: View {
    var body: some View {
        let latest = Array(QuickSample.pieces.prefix(6))
        let latestIDs = Set(latest.map(\.id))
        LazyVStack(alignment: .leading, spacing: 0) {
            QuickSection(title: "The Latest", pieces: latest, first: true)
            ForEach(Place.departments) { department in
                let all = QuickSample.pieces(in: department)
                let rest = all.filter { !latestIDs.contains($0.id) }
                QuickSection(title: department.name, pieces: rest.isEmpty ? all : rest)
            }
        }
    }
}

private struct QuickDepartment: View {
    let place: Place

    var body: some View {
        let categories = (QuickSample.categories[place] ?? []).filter { !QuickSample.pieces(in: place, category: $0.name).isEmpty }
        LazyVStack(alignment: .leading, spacing: 0) {
            QuickTileRow(tiles: categories)
            ForEach(Array(categories.enumerated()), id: \.element.name) { index, category in
                QuickSection(title: category.name, pieces: QuickSample.pieces(in: place, category: category.name), first: index == 0)
            }
        }
    }
}

/// A category heading (display face, spaced capitals, a hairline to the right) and its pieces, two across.
private struct QuickSection: View {
    let title: String
    let pieces: [QuickPiece]
    var first = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 14) {
                Text(title).textStyle(.categoryHeading).foregroundStyle(.ink)
                    .accessibilityAddTraits(.isHeader)
                Rectangle().fill(.line).frame(height: 1)
            }
            .padding(.horizontal, 16)
            QuickGrid(pieces: pieces)
        }
        .padding(.top, first ? 22 : 48)
    }
}

/// Two across, edge to edge: the photos run to the screen's sides with 3pt between them; rows 32pt apart.
struct QuickGrid: View {
    let pieces: [QuickPiece]

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 3), GridItem(.flexible(), spacing: 3)], alignment: .leading, spacing: 32) {
            ForEach(pieces) { piece in
                QuickCard(piece: piece)
            }
        }
    }
}

/// Designer, name, price · size, under the photo (4:5, cropped from the middle) with the heart on it.
struct QuickCard: View {
    let piece: QuickPiece

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            LocalPhoto(url: piece.photo)
                .aspectRatio(4 / 5, contentMode: .fit)
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "heart")
                        .font(.system(size: 17, weight: .light))
                        .foregroundStyle(.ink)
                        .frame(width: 44, height: 44)
                        .padding(.top, -4)
                        .accessibilityLabel("Save")
                        .accessibilityAddTraits(.isButton)
                }
            VStack(alignment: .leading, spacing: 4) {
                Text(piece.designer)
                    .textStyle(.cardDesigner)
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                    .minimumScaleFactor(11 / 13)
                Text(piece.name)
                    .textStyle(.cardName)
                    .foregroundStyle(.ink2)
                    .lineLimit(2)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(piece.price.priceText).textStyle(.cardPrice).foregroundStyle(.ink)
                    let sizes = Sizes.words(piece.sizes, range: true)
                    if !sizes.isEmpty {
                        Text("·").textStyle(.cardSize).foregroundStyle(.muted)
                        Text(sizes).textStyle(.cardSize).foregroundStyle(.muted).lineLimit(1)
                    }
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .padding(.top, 12)
        }
        .accessibilityElement(children: .combine)
    }
}

/// The department's tile row: the cutouts from the site, shown whole on their 4:3 canvas, bottom-aligned, with one
/// soft shadow (`--e-obj`, to match side by side in browse/departments), all fitting one screen width.
private struct QuickTileRow: View {
    let tiles: [(name: String, tile: String)]

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            ForEach(tiles, id: \.name) { tile in
                VStack(spacing: 6) {
                    TileImage(name: tile.tile)
                        .frame(width: 64, height: 48)
                        .shadow(color: .ink.opacity(0.12), radius: 3.5, y: 9)
                        .shadow(color: .ink.opacity(0.07), radius: 1, y: 2)
                    Text(tile.name).textStyle(.tileLabel).foregroundStyle(.ink2)
                }
                .frame(maxWidth: 92)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
                .accessibilityAddTraits(.isButton)
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 18)
        .padding(.bottom, 4)
    }
}

struct TileImage: View {
    let name: String

    var body: some View {
        if let url = StoreConfig.siteAssetsURL?.appending(path: "tiles/\(name).webp"), let image = UIImage(contentsOfFile: url.path()) {
            Image(uiImage: image).resizable().aspectRatio(4 / 3, contentMode: .fit)
        } else {
            Color.clear
        }
    }
}

// MARK: Home

/// A stand-in for the home page (the real one comes with the home step): the hero and the Just listed shelf.
private struct QuickHome: View {
    var body: some View {
        let jackie = QuickSample.pieces.first { $0.id == "gucci-jackie-1961-medium-tote" }
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Women · Handbags").textStyle(.sectionLabel).foregroundStyle(.muted)
                Text("Gucci Jackie 1961").textStyle(TextStyle(face: .display, size: 28, tracking: 0.06, uppercase: true)).foregroundStyle(.ink)
                Text("The medium tote in emerald calfskin, closed with the gold-tone piston hardware.")
                    .textStyle(TextStyle(face: .body(.regular), size: 15, lineHeight: 1.5)).foregroundStyle(.ink2)
                if let jackie {
                    Text(jackie.price.priceText).textStyle(.cardPrice).foregroundStyle(.ink)
                }
                Text("Shop now")
                    .textStyle(.button)
                    .foregroundStyle(.paper)
                    .frame(height: 48)
                    .padding(.horizontal, 32)
                    .background(Rectangle().fill(.ink))
                    .padding(.top, 6)
                    .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)

            LocalPhoto(url: jackie?.photo, contentMode: .fit, ground: .paper)
                .aspectRatio(4 / 5, contentMode: .fit)
                .containerRelativeFrame(.horizontal) { width, _ in width * 0.86 }
                .frame(maxWidth: .infinity)
                .padding(.top, 28)

            HStack(spacing: 14) {
                Text("Just listed").textStyle(.categoryHeading).foregroundStyle(.ink)
                Rectangle().fill(.line).frame(height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.top, 40)
            .padding(.bottom, 16)

            ScrollView(.horizontal) {
                LazyHStack(alignment: .top, spacing: 3) {
                    ForEach(QuickSample.pieces.prefix(10)) { piece in
                        QuickCard(piece: piece).frame(width: 170)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }
}
