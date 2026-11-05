import SwiftUI
import UIKit

extension HomeContent {
    /// Home from the closet (the site's `HomePage.tsx` and `Turntable.tsx`): the three bags with their pieces' credits,
    /// and each room's pieces from its "Home row" collection, placed by the home size standard.
    static func make(closet: Closet, app: AppState) -> HomeContent {
        HomeContent(bags: bags(closet: closet, app: app), rooms: rooms(closet: closet, app: app))
    }

    /// A bag on the table and its piece in the shop. Until it's listed (the Bréa today) it says "New arrival" and leads
    /// to Women › Handbags; once a piece with its id is in the shop, its listing, price and page take over by themselves.
    private static func bags(closet: Closet, app: AppState) -> [TableBag] {
        Merch.turntable.bags.map { bag in
            let image = bag.cutURL.flatMap { UIImage(contentsOfFile: $0.path()) }
            if let piece = closet.piece(id: bag.id) {
                let price = priceText(piece.price)
                return TableBag(
                    id: bag.id, image: image, cm: bag.cm, top: bag.top, bot: bag.bot,
                    designer: piece.designer, name: bag.name, sub: price,
                    label: "\(piece.designer) \(piece.title), \(price)",
                    open: { app.open(piece) }
                )
            }
            let soon = bag.soon
            return TableBag(
                id: bag.id, image: image, cm: bag.cm, top: bag.top, bot: bag.bot,
                designer: soon?.designer ?? "", name: bag.name, sub: soon?.note ?? "",
                label: soon.map { "\($0.designer) \($0.title), \($0.note)" } ?? bag.name,
                open: { app.open(.women) }
            )
        }
    }

    /// Each room's pieces, in its collection's order (the first eight for sale); a room with none is left out.
    private static func rooms(closet: Closet, app: AppState) -> [HomeRoomRow] {
        Merch.homeRooms.compactMap { room in
            let tiles: [HomeRoomTile] = (closet.rooms[room.collection] ?? []).compactMap { pick in
                guard let piece = closet.piece(handle: pick.handle), let photo = homePhoto(piece, fit: pick.fit) else { return nil }
                return HomeRoomTile(
                    id: piece.id, designer: piece.designer, price: priceText(piece.price),
                    url: sizedImageURL(photo.url, width: 600), alt: photo.alt,
                    width: photo.fit.width, left: photo.fit.left, top: photo.fit.top, grow: photo.fit.grow,
                    open: { app.open(piece) }
                )
            }
            guard !tiles.isEmpty else { return nil }
            return HomeRoomRow(
                id: room.collection, name: room.name, place: ShopPlace(room.dept), tiles: tiles,
                count: closet.count(dept: room.dept, cat: room.cat)
            )
        }
    }

    /// The photo a room shows for a piece: its cover, placed where the Photo sizes run measured it; or, for a piece
    /// that shows another of its own photos (the Coppley's jacket alone), that photo once the piece has it. Not
    /// measured on this cover yet: 80% of the tile's width, in the middle, its bottom on the foot line.
    static func homePhoto(_ piece: Piece, fit: HomeFit?) -> (url: URL, alt: String, fit: HomeFit)? {
        if let other = Merch.homePhoto[piece.id], let photo = piece.morePhotos?.first(where: { other.matches($0.url) }) {
            return (photo.url, other.alt, other.fit)
        }
        guard let image = piece.image else { return nil }
        let w = Merch.homeStandard.fallback * 100
        let tall = image.width.flatMap { w in image.height.map { Double($0) / Double(max(1, w)) } } ?? 1.25
        return (image.url, image.alt, fit ?? HomeFit(width: w, left: (100 - w) / 2, top: Merch.homeStandard.foot * 100 - w * tall, grow: 1))
    }
}

extension ShopPlace {
    init(_ dept: Dept) {
        switch dept {
        case .women: self = .women
        case .men: self = .men
        case .jewelry: self = .jewelry
        }
    }
}
