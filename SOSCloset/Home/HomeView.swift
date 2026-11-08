import SwiftUI
import UIKit

/// Home, as on soscloset.com (APP-SPEC §3.4; SPEC §11a; Sam, November 5: "check the homepage of the actual website with
/// the carousel of the bags … and replicate that"). All white, top to bottom: the opening (the words, Shop women and
/// Shop men, the turntable of three bags and the front bag's credit), the four rooms, and the service notes with the
/// footer's disclosure. Under the header with no tab underlined; Menu and the logo stay as you scroll.
struct HomeView: View {
    @Environment(AppState.self) private var app
    @Environment(Closet.self) private var closet
    @State private var table = TurntableModel(count: Merch.turntable.bags.count, front: Merch.turntable.front)

    var body: some View {
        let content = HomeContent.make(closet: closet, app: app)
        HeaderPage(current: nil, refresh: { await closet.refresh() }) { width in
            VStack(spacing: 0) {
                opening(width: width, content: content)
                ForEach(content.rooms) { room in
                    RoomRowView(room: room, width: width) { app.open(room.place, at: room.cat) }
                        .padding(.top, 64)
                }
                ServiceNotes()
                    .padding(.top, 72)
            }
        }
    }

    // MARK: The opening

    /// Centred: "Beautiful things.", one line under it, Shop women (solid ink) and Shop men (outlined), then the
    /// turntable. 32pt above the words; 6pt between the buttons and the table (SPEC §11a, phones).
    private func opening(width: CGFloat, content: HomeContent) -> some View {
        VStack(spacing: 0) {
            Text("Beautiful things.")
                .textStyle(.homeTitle)
                .foregroundStyle(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.gutter(forWidth: width))
                .accessibilityAddTraits(.isHeader)
            Text("Louis Vuitton, Gucci, Hermès and more.")
                .textStyle(.homeLine)
                .foregroundStyle(.ink2)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Layout.gutter(forWidth: width))
                .padding(.top, 14)
            HStack(spacing: 12) {
                shopButton("Shop women", solid: true) { app.open(.women) }
                shopButton("Shop men", solid: false) { app.open(.men) }
            }
            .padding(.top, 22)
            TurntableView(bags: content.bags, front: Merch.turntable.front, width: width, model: table)
                .padding(.top, 6)
        }
        .padding(.top, 32)
        .frame(maxWidth: .infinity)
    }

    /// 46pt tall, 12pt semibold spaced capitals, square (content is square: SPEC §12).
    private func shopButton(_ title: String, solid: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .textStyle(.homeButton)
                .foregroundStyle(solid ? Color.paper : Color.ink)
                .lineLimit(1)
                .fixedSize()
                .padding(.horizontal, 22)
                .frame(height: 46)
                .background(solid ? Color.ink : Color.paper)
                .overlay(Rectangle().strokeBorder(.ink, lineWidth: 1))
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
    }
}

/// What Home shows from the closet: the three bags (with their pieces' credits) and the rooms' pieces.
struct HomeContent {
    var bags: [TableBag]
    var rooms: [HomeRoomRow]

    static let empty = HomeContent(bags: [], rooms: [])
}

// MARK: - The rooms

/// A room (SPEC §11a): its title, which is the link to the department at that category; up to eight pieces in one
/// sideways row of square tiles; then View all, with the category's count.
struct HomeRoomRow: Identifiable {
    let id: String
    let name: String
    let place: ShopPlace
    /// The category its title and View all land at ("/women#clothing").
    let cat: String
    let tiles: [HomeRoomTile]
    let count: Int
}

/// A piece in a room: its photo placed in the square tile by the home size standard, and its credit.
struct HomeRoomTile: Identifiable {
    let id: String
    let designer: String
    let price: String
    let url: URL?
    let alt: String
    /// Width, left and top as % of the tile, and g, how much it grows on phones (shoes 1).
    let width: Double
    let left: Double
    let top: Double
    let grow: Double
    let open: () -> Void
}

struct RoomRowView: View {
    let room: HomeRoomRow
    let width: CGFloat
    let openRoom: () -> Void

    @Environment(\.pieceZoom) private var zoom

    /// Two tiles and about a third of the next in view: `(width − 32 − 24) / 2.3`, 12pt apart.
    private var tile: CGFloat { ((width - 2 * Layout.gutter(forWidth: width) - 24) / 2.3).rounded(.down) }
    /// Phones (under 761pt wide) grow clothing by its g about the middle of its foot.
    private var phone: Bool { width < 761 }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            title
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 12) {
                    ForEach(room.tiles) { piece($0) }
                    viewAll
                }
                .scrollTargetLayout()
            }
            .contentMargins(.horizontal, Layout.gutter(forWidth: width), for: .scrollContent)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .contain)
    }

    /// The room's name in the display face's spaced capitals and a small chevron, the whole of it one link (44pt tall),
    /// flush left at the gutter, a hairline running from 14pt after it to the screen's edge.
    private var title: some View {
        HStack(spacing: 14) {
            Button(action: openRoom) {
                HStack(spacing: 4) {
                    Text(room.name)
                        .textStyle(.roomTitle)
                        .foregroundStyle(.ink)
                        .lineLimit(1)
                        .fixedSize()
                    Polyline(box: CGSize(width: 7, height: 12), points: [(1, 1), (6, 6), (1, 11)])
                        .stroke(.muted, style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
                        .frame(width: 7, height: 12)
                }
                .frame(minHeight: 44)
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(.isHeader)
            Rectangle().fill(.line).frame(height: 1).frame(minWidth: 24)
        }
        .padding(.leading, Layout.gutter(forWidth: width))
    }

    private func piece(_ p: HomeRoomTile) -> some View {
        let g = phone ? p.grow : 1
        let w = p.width * g
        let left = 50 - (50 - p.left) * g
        let top = 96.5 - (96.5 - p.top) * g
        return Button(action: p.open) {
            VStack(spacing: 10) {
                LoadedPhoto(url: p.url) { image in
                    let iw = tile * w / 100
                    let ih = iw * image.size.height / max(1, image.size.width)
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: iw, height: ih)
                        .offset(x: tile * left / 100, y: tile * top / 100)
                        .frame(width: tile, height: tile, alignment: .topLeading)
                }
                .frame(width: tile, height: tile)
                .background(.paper)
                .clipped()
                .zoomSource(HomeRoomTile.zoomID(p.id), in: zoom)
                credit(p.designer, p.price)
            }
            .frame(width: tile)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(p.designer), \(p.price)")
        .accessibilityAddTraits(.isLink)
    }

    /// The row ends on View all: a thin ink ring (34% of the tile, 60% down) with a chevron, and a credit like a piece's.
    private var viewAll: some View {
        Button(action: openRoom) {
            VStack(spacing: 10) {
                ZStack {
                    let ring = tile * 0.34
                    Circle()
                        .strokeBorder(.ink, lineWidth: 1)
                        .frame(width: ring, height: ring)
                        .overlay {
                            Polyline(box: CGSize(width: 24, height: 24), points: [(9, 5), (16, 12), (9, 19)])
                                .stroke(.ink, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                                .frame(width: ring * 0.34, height: ring * 0.34)
                        }
                        .position(x: tile / 2, y: tile * 0.6)
                }
                .frame(width: tile, height: tile)
                credit("View all", "\(room.count) pieces")
            }
            .frame(width: tile)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("View all \(room.count) pieces of \(room.name)")
        .accessibilityAddTraits(.isLink)
    }

    /// Under a tile, centred: the designer (10pt spaced capitals), the price under it (11pt, muted), 4pt apart.
    private func credit(_ designer: String, _ price: String) -> some View {
        VStack(spacing: 4) {
            Text(designer)
                .textStyle(.creditDesigner)
                .foregroundStyle(.ink)
            Text(price)
                .textStyle(.creditLine)
                .foregroundStyle(.muted)
                .monospacedDigit()
        }
        .multilineTextAlignment(.center)
        .lineLimit(2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - The service notes

/// At the foot of Home (SPEC §11a, §2): Ask SOS Closet, Follow SOS Closet and Consign with us, as mail and Instagram
/// links, then the footer's disclosure, above a hairline.
struct ServiceNotes: View {
    static let email = "soscloset33@gmail.com"
    static let instagram = URL(string: "https://www.instagram.com/soscloset33/")!
    static let instagramHandle = "@SOSCLOSET33"

    var body: some View {
        VStack(spacing: 40) {
            note("Ask SOS Closet", "Questions about a piece, its sizing or its details? Write to us.",
                 link: Self.email, url: URL(string: "mailto:\(Self.email)")!)
            note("Follow SOS Closet", "See new pieces as they come in on Instagram.",
                 link: Self.instagramHandle, url: Self.instagram)
            note("Consign with us", "We photograph, price, list and ship your pieces for you.",
                 link: "Start a consignment", url: URL(string: "mailto:\(Self.email)?subject=Consignment")!)
            Text("Pieces are pre-owned unless marked New with tags. SOS Closet is independent and is not affiliated with, authorized by or endorsed by any brand it sells. All trademarks belong to their owners.")
                .textStyle(.disclosure)
                .foregroundStyle(.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 8)
        }
        .padding(.horizontal, 16)
        .padding(.top, 56)
        .padding(.bottom, 48)
        .frame(maxWidth: .infinity)
        .overlay(alignment: .top) { Rectangle().fill(.line).frame(height: 1) }
    }

    private func note(_ title: String, _ words: String, link: String, url: URL) -> some View {
        VStack(spacing: 10) {
            Text(title)
                .textStyle(.noteTitle)
                .foregroundStyle(.ink)
                .accessibilityAddTraits(.isHeader)
            Text(words)
                .textStyle(.noteText)
                .foregroundStyle(.ink2)
                .frame(maxWidth: 320)
            Link(destination: url) {
                Text(link)
                    .textStyle(.noteLink)
                    .foregroundStyle(Color.link)
                    .underline()
                    .padding(.vertical, 10)
            }
        }
        .multilineTextAlignment(.center)
    }
}

/// A line through points given in a box of the site's SVG units (`viewBox`), drawn at the frame's size.
nonisolated struct Polyline: Shape {
    let box: CGSize
    let points: [(Double, Double)]

    func path(in rect: CGRect) -> Path {
        var p = Path()
        for (i, (x, y)) in points.enumerated() {
            let pt = CGPoint(x: rect.minX + x / box.width * rect.width, y: rect.minY + y / box.height * rect.height)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        return p
    }
}
