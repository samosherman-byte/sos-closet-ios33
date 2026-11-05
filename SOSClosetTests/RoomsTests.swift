import Foundation
import Testing
@testable import SOSCloset

// The home page's rooms (SPEC §11a): the cases of the site's app/lib/home/rooms.test.ts. Each room's pieces come from
// its "Home row" collection, the first for sale, placed as the Photo sizes run measured each cover.

private func json(_ v: Any) -> String {
    String(data: try! JSONSerialization.data(withJSONObject: v, options: [.fragmentsAllowed]), encoding: .utf8)!
}

private func record(_ handle: String, photoFit: String? = nil, coverId: String? = nil) -> ProductRecord {
    ProductRecord(
        handle: handle, title: handle, vendor: "V", productType: "Clothing", tags: [], createdAt: "2026-10-30T00:00:00Z",
        images: [PieceImage(url: URL(string: "https://cdn/\(handle).jpg")!, alt: "", width: 4, height: 5)],
        coverId: coverId ?? "gid://shopify/MediaImage/\(handle)",
        variants: [Variant(id: handle, size: nil, available: true, price: 100)],
        metafields: .init(photoFit: photoFit))
}

@Suite("homeFit: the stored place, for the cover it was measured on, to the current standard")
struct HomeFitTests {
    let v: [String: Any] = [
        "scale": 1, "drop": 0, "top": 10,
        "home": ["garment": [94.04, 2.51, -7.15, 1.063], "shoes": [86.03, 6.65, -1.48, 1]],
        "homeVersion": 4, "imageId": "m1",
    ]

    func with(_ more: [String: Any]) -> [String: Any] { v.merging(more) { _, new in new } }

    @Test func thePlaceForTheRoomsKindOfPieceWithHowMuchItGrows() {
        #expect(homeFit(json(v), coverId: "m1", kind: .garment) == HomeFit(width: 94.04, left: 2.51, top: -7.15, grow: 1.063))
        #expect(homeFit(json(v), coverId: "m1", kind: .shoes) == HomeFit(width: 86.03, left: 6.65, top: -1.48, grow: 1))
    }

    @Test func noneForAPlaceMeasuredToAnOlderStandard() {
        let oct31 = with(["home": ["garment": [75.78, 11.73, 12.97, 1.1], "shoes": [86.03, 6.65, -1.48, 1]], "homeVersion": 3])
        let oct30 = with(["home": ["garment": [75.78, 11.73, 12.97], "shoes": [86.03, 6.65, -1.48]], "homeVersion": 2])
        var oct29 = with(["home": ["garment": [92.12, 3.48, 13.77], "evening": [90, 5, 14]]])
        oct29["homeVersion"] = nil
        var oct29v1 = oct29
        oct29v1["homeVersion"] = 1
        for old in [oct31, oct30, oct29, oct29v1] {
            for kind in HomeKind.allCases {
                #expect(homeFit(json(old), coverId: "m1", kind: kind) == nil, "\(old["homeVersion"] ?? "none") \(kind)")
            }
        }
        // (Four numbers to the current standard, never three.)
        #expect(homeFit(json(with(["home": ["garment": [75, 11, 13]]])), coverId: "m1", kind: .garment) == nil)
    }

    @Test func noneForAnotherCoverAnotherKindOrNoHomeYet() {
        #expect(homeFit(json(v), coverId: "m2", kind: .garment) == nil)
        #expect(homeFit(json(with(["home": ["garment": [75, 12, 13, 1.1]]])), coverId: "m1", kind: .shoes) == nil)
        var noHome = v
        noHome["home"] = nil
        #expect(homeFit(json(noHome), coverId: "m1", kind: .garment) == nil)
        #expect(homeFit(json(with(["home": [String: Any]()])), coverId: "m1", kind: .garment) == nil)
        #expect(homeFit(nil, coverId: "m1", kind: .garment) == nil)
        #expect(homeFit(json(v), coverId: nil, kind: .garment) == nil)
    }

    @Test func noneForAValueTheToolWouldntWrite() {
        let bad: [Any] = [
            [1, 2], [0, 0, 0, 1], ["a", 1, 2, 1] as [Any], [92, 300, 1, 1], [75, 11, 13, 1.3], [75, 11, 13, 0.9],
            [75, 11, 13, "x"] as [Any], "x",
        ]
        for b in bad {
            #expect(homeFit(json(with(["home": ["garment": b]])), coverId: "m1", kind: .garment) == nil, "\(b)")
        }
        #expect(homeFit("{not json", coverId: "m1", kind: .garment) == nil)
    }
}

@Suite("roomPicks: the first pieces for sale, in the collection's order")
struct RoomPicksTests {
    let room = Merch.HomeRoom(
        name: "Women’s clothing", dept: .women, cat: "Clothing", href: "/women#clothing", kind: .garment,
        collection: "home-row-womens-clothing", show: 3)
    let placed = json(["home": ["garment": [90, 5, 14, 1.05]], "homeVersion": 4, "imageId": "m-b"] as [String: Any])

    @Test func inOrderTheFirstThreeForSaleEachWithItsPlace() {
        let recs = ["a", "b", "c", "d", "e"].map { h in record(h, photoFit: h == "b" ? placed : nil, coverId: "m-\(h)") }
        let picks = roomPicks(
            ["home-row-womens-clothing": ["e", "b", "a", "d", "c"]], recs, forSale: ["a", "b", "c", "e"], rooms: [room])
        #expect(
            picks["home-row-womens-clothing"] == [
                RoomPick(handle: "e"),
                RoomPick(handle: "b", fit: HomeFit(width: 90, left: 5, top: 14, grow: 1.05)),
                RoomPick(handle: "a"),
            ])
    }

    @Test func aRoomWithNothingForSaleOrMissingHasNone() {
        let recs = [record("a")]
        #expect(roomPicks(["home-row-womens-clothing": ["a", "z"]], recs, forSale: [], rooms: [room]) == ["home-row-womens-clothing": []])
        #expect(roomPicks([:], recs, forSale: ["a"], rooms: [room]) == ["home-row-womens-clothing": []])
    }

    @Test func aPieceWithoutAPhotoIsLeftOut() {
        var a = record("a")
        a.images = []
        #expect(
            roomPicks(["home-row-womens-clothing": ["a", "b"]], [a, record("b")], forSale: ["a", "b"], rooms: [room])[
                "home-row-womens-clothing"] == [RoomPick(handle: "b")])
    }

    @Test func upToEightARoom() {
        let handles = "abcdefghijk".map(String.init)
        let picks = roomPicks(
            ["home-row-mens-shoes": handles], handles.map { record($0) }, forSale: Set(handles.filter { $0 != "c" }),
            rooms: Merch.homeRooms.filter { $0.collection == "home-row-mens-shoes" })
        #expect(picks["home-row-mens-shoes"]?.map(\.handle) == "abdefghi".map(String.init))
    }
}

@Suite("The sample store's rooms (data/merch.json home_page.rooms)",
    .enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
struct SampleRoomsTests {
    let picks = roomPicks(
        SampleFiles.catalog.roomLists, SampleFiles.records, forSale: Set(SampleFiles.pieces.map(\.handle)))
    let ids = Dictionary(SampleFiles.pieces.map { ($0.handle, $0.id) }, uniquingKeysWith: { a, _ in a })

    @Test func thePrototypesPicksTheSampleStoreHasInItsOrder() {
        #expect(
            Merch.homeRooms.map { r in (picks[r.collection] ?? []).map { ids[$0.handle] ?? "?" } } == [
                ["staud-gus", "sc026", "c154", "sc014", "sc029", "gwyn", "c118"],
                ["coppley", "av21-dinner", "bordeaux-blazer", "av21-navy", "c14", "c6"],
                ["sc007", "paige-boots", "choo", "c181", "sc003", "c102", "c46"],
                ["c183", "yz-carbon", "c2", "c184"],
            ])
    }

    @Test func eachPlacedAsMeasuredOnItsCover() {
        let unplaced = Merch.homeRooms.flatMap { r in
            (picks[r.collection] ?? []).filter { $0.fit == nil }.map { ids[$0.handle] ?? "?" }
        }
        // (The sample store's booties cover isn't on white: it shows by the fallback.)
        #expect(unplaced == ["paige-boots"])
    }
}
