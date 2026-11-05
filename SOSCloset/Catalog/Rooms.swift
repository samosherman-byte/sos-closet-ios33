import Foundation

// The home page's rooms (SPEC §11a), ported from the site's app/lib/home/rooms.ts: each room's pieces are a Shopify
// collection Sam keeps in order ("Home row · …"), and each piece stands where the Photo sizes run measured its cover
// (tools/photo_fit.py, `home` in the product's sos.photo_fit metafield).

/// Where a photo sits in its square tile (merch.ts `HomeFit`): its width, left and top, as % of the tile, and how much
/// it grows on phones (`grow`, the site's g: 1 to 1.1; shoes 1).
nonisolated struct HomeFit: Hashable, Sendable {
    var width: Double
    var left: Double
    var top: Double
    var grow: Double
}

/// A piece in a room: its handle, and its place in the room's tile when it was measured on its current cover
/// (rooms.ts `RoomPick`).
nonisolated struct RoomPick: Hashable, Sendable {
    var handle: String
    var fit: HomeFit?
}

/// Each room's pieces, by its collection's handle (rooms.ts `RoomPicks`).
typealias RoomPicks = [String: [RoomPick]]

/// Where the cover sits in a tile of this kind, from the sos.photo_fit metafield: only when it was measured on the
/// cover the piece shows now, to the current home size standard (`homeVersion`; a new cover, or one measured to an
/// older standard, shows by the fallback meanwhile). A value the tool wouldn't write is ignored. rooms.ts `homeFit`.
nonisolated func homeFit(_ raw: String?, coverId: String?, kind: HomeKind) -> HomeFit? {
    guard let raw, !raw.isEmpty, let coverId, !coverId.isEmpty,
        let v = jsonValue(raw) as? [String: Any],
        // (A number, and this one: an older standard's place, or none, waits for the next run.)
        let version = v["homeVersion"] as? NSNumber, version.doubleValue == Double(Merch.homeStandard.version),
        (v["imageId"] as? String) == coverId,
        let home = v["home"] as? [String: Any],
        let at = home[kind.rawValue] as? [Any], at.count == 4
    else { return nil }
    let n = at.map { jsNumber($0) }
    let (w, left, top, g) = (n[0], n[1], n[2], n[3])
    guard w > 5 && w < 300, abs(left) < 100, abs(top) < 100, g >= 1 && g <= Merch.homeStandard.grow else { return nil }
    return HomeFit(width: w, left: left, top: top, grow: g)
}

/// Which pieces each room shows: of its collection's products (handles, in the collection's order), the first `show`
/// that are for sale, each with its stored place. A piece that sells drops out and the next takes its place; a room
/// with nothing for sale has none, and is left out. rooms.ts `roomPicks`.
nonisolated func roomPicks(
    _ lists: [String: [String]], _ records: [ProductRecord], forSale: Set<String>,
    rooms: [Merch.HomeRoom] = Merch.homeRooms
) -> RoomPicks {
    let byHandle = Dictionary(records.map { ($0.handle, $0) }, uniquingKeysWith: { _, last in last })
    var out: RoomPicks = [:]
    for room in rooms {
        var picks: [RoomPick] = []
        for handle in lists[room.collection] ?? [] {
            guard let r = byHandle[handle], !r.images.isEmpty, forSale.contains(handle) else { continue }
            picks.append(RoomPick(handle: handle, fit: homeFit(r.metafields.photoFit, coverId: r.coverId, kind: room.kind)))
            if picks.count == room.show { break }
        }
        out[room.collection] = picks
    }
    return out
}
