import Foundation
import SwiftUI
import Testing
@testable import SOSCloset

// The closet the app shows: loading it from the sample store, a store not connected yet, a refresh that fails, and
// the freshness rule (APP-SPEC §3.1).

/// Counts fetches; fails them from the `failFrom`th on.
private actor Fetches {
    var count = 0
    func next() -> Int {
        count += 1
        return count
    }
}

private nonisolated struct CountingSource: CatalogSource {
    let fetches: Fetches
    var failFrom = Int.max

    func catalog(roomCollections: [String]) async throws -> SourceCatalog {
        let n = await fetches.next()
        if n >= failFrom { throw CatalogError.unreachable }
        let record = ProductRecord(
            handle: "piece-\(n)", title: "Piece", vendor: "V", productType: "Handbags", tags: ["id:p\(n)"],
            createdAt: "2026-10-20T00:00:00Z", variants: [Variant(id: "v", size: nil, available: true, price: 100)])
        return SourceCatalog(records: [record], roomLists: [:])
    }

    func product(handle: String, in records: [ProductRecord]) async throws -> ProductRecord? {
        records.first { $0.handle == handle }
    }
}

@Suite("The closet")
struct ClosetTests {
    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func loadsTheSampleStore() async throws {
        let closet = Closet(source: SampleStoreSource(folder: SampleFiles.folder))
        #expect(closet.state == .loading)
        await closet.load()
        #expect(closet.state == .loaded)
        #expect(closet.loadedAt != nil)
        #expect(closet.pieces.map(\.id) == SampleFiles.pieces.map(\.id))
        #expect(closet.pieces.count == SampleFiles.catalogJSON.items.count)
        // The four rooms, by collection.
        #expect(Set(closet.rooms.keys) == Set(Merch.homeRooms.map(\.collection)))
        #expect(closet.rooms["home-row-mens-shoes"]?.count == 4)
        // View all's count: the category's pieces.
        let womensClothing = closet.pieces.filter { $0.dept == .women && $0.cat == "Clothing" }.count
        #expect(womensClothing > 0)
        #expect(closet.count(dept: .women, cat: "Clothing") == womensClothing)
        #expect(closet.count(dept: .women) == closet.pieces.filter { $0.dept == .women }.count)
        // By handle and by id.
        #expect(closet.piece(handle: "gucci-jackie-1961-medium-tote")?.id == "jackie")
        #expect(closet.piece(id: "jackie")?.handle == "gucci-jackie-1961-medium-tote")
        #expect(closet.piece(id: "nothing") == nil)
        // A piece's page.
        let page = try #require(try await closet.productDetail(handle: "gucci-jackie-1961-medium-tote"))
        #expect(page.photos.count == 4)
        #expect(page.colorName == "Emerald green")
        #expect(try await closet.productDetail(handle: "no-such-piece") == nil)
    }

    @Test func aStoreNotConnectedYetSaysSoPlainly() async {
        let closet = Closet(source: StorefrontSource(endpoint: nil, token: ""))
        await closet.load()
        #expect(closet.state == .failed(CatalogError.notConfigured.errorDescription!))
        #expect(closet.pieces.isEmpty)
        #expect(closet.rooms.isEmpty)
        #expect(closet.count(dept: .women) == 0)
    }

    @Test func aSampleStoreThatIsntThereSaysSo() async {
        let closet = Closet(source: SampleStoreSource(folder: URL(fileURLWithPath: "/nonexistent/SampleStore")))
        await closet.load()
        #expect(closet.state == .failed(CatalogError.sampleStoreMissing.errorDescription!))
    }

    @Test func loadOnceRefreshAgain() async {
        let fetches = Fetches()
        let closet = Closet(source: CountingSource(fetches: fetches))
        await closet.load()
        await closet.load()
        #expect(await fetches.count == 1)
        await closet.refresh()
        #expect(await fetches.count == 2)
        #expect(closet.pieces.map(\.handle) == ["piece-2"])
    }

    @Test func aRefreshThatFailsKeepsTheCloset() async {
        let closet = Closet(source: CountingSource(fetches: Fetches(), failFrom: 2))
        await closet.load()
        await closet.refresh()
        #expect(closet.state == .loaded)
        #expect(closet.pieces.map(\.handle) == ["piece-1"])
        #expect(closet.refreshError == CatalogError.unreachable.errorDescription)
    }

    @Test func comesBackAfterAMinuteOrMoreAndFetchesAgain() async {
        let fetches = Fetches()
        let closet = Closet(source: CountingSource(fetches: fetches))
        await closet.load()
        let t0 = Date(timeIntervalSince1970: 1_000_000)
        // Away 30 seconds: as it was.
        closet.scenePhaseChanged(to: .background, at: t0)
        #expect(closet.scenePhaseChanged(to: .active, at: t0 + 30) == nil)
        // Away a minute: fetched again.
        closet.scenePhaseChanged(to: .background, at: t0 + 100)
        closet.scenePhaseChanged(to: .inactive, at: t0 + 150)
        let task = closet.scenePhaseChanged(to: .active, at: t0 + 160)
        #expect(task != nil)
        await task?.value
        #expect(await fetches.count == 2)
        // (Active again without going away: nothing.)
        #expect(closet.scenePhaseChanged(to: .active, at: t0 + 500) == nil)
    }

    @Test func theFreshnessRule() {
        let t = Date(timeIntervalSince1970: 0)
        #expect(!Closet.shouldRefetch(awaySince: nil, now: t))
        #expect(!Closet.shouldRefetch(awaySince: t, now: t + 59.9))
        #expect(Closet.shouldRefetch(awaySince: t, now: t + 60))
    }
}
