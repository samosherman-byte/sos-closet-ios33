import Foundation
import Observation
import SwiftUI

/// The closet the app shows: every piece for sale, newest first, hold-backs applied, with the case's story lines
/// (`closetOf`), and the home page's rooms (`roomPicks`), loaded from this build's store (APP-SPEC §3.1, the site's
/// app/lib/catalog/index.server.ts).
///
/// Freshness (APP-SPEC §3.1): one fetch of the whole closet when the app opens (`load()`), again when it comes back
/// after a minute or more away (`scenePhaseChanged(to:)`), and on pull to refresh (`refresh()`). A piece that sells
/// disappears at the next fetch; checkout never sells a piece twice.
@MainActor @Observable final class Closet {
    enum LoadState: Equatable, Sendable {
        /// The first load is under way (nothing to show yet).
        case loading
        /// The closet is here (a refresh that fails keeps it, and says so in `refreshError`).
        case loaded
        /// The closet couldn't load, and why, in words for the screen.
        case failed(String)
    }

    private(set) var state: LoadState = .loading
    /// Every piece for sale, in the closet's order.
    private(set) var pieces: [Piece] = []
    /// Each home room's pieces, by its collection's handle (`Merch.homeRooms[i].collection`). A room with nothing for
    /// sale has none, and is left out; if the store couldn't say what's in the collections, there are none.
    private(set) var rooms: RoomPicks = [:]
    /// When the closet was last fetched.
    private(set) var loadedAt: Date?
    /// A refresh that failed while the closet was already showing: what to say, quietly. Nil once one works.
    private(set) var refreshError: String?

    /// Where the closet comes from.
    let source: any CatalogSource
    /// Away this long or more, coming back fetches the closet again.
    nonisolated static let comeBackAfter: TimeInterval = 60

    @ObservationIgnored private var records: [ProductRecord] = []
    @ObservationIgnored private var byHandle: [String: Int] = [:]
    @ObservationIgnored private var byID: [String: Int] = [:]
    @ObservationIgnored private var inFlight: Task<Void, Never>?
    @ObservationIgnored private var awaySince: Date?

    init(source: any CatalogSource) {
        self.source = source
    }

    /// The closet of this build's store (`StoreConfig`): the sample store in Debug builds that read it, otherwise Sam's
    /// store. Without the store's address and token (or the sample store's files), it loads to a plain message
    /// saying so, and nothing else breaks.
    static func forThisBuild() -> Closet {
        switch StoreConfig.source {
        case .sample:
            guard let folder = StoreConfig.sampleStoreURL else {
                return Closet(source: UnavailableSource(error: .sampleStoreMissing))
            }
            return Closet(source: SampleStoreSource(folder: folder))
        case .shopify:
            return Closet(source: StorefrontSource(endpoint: StoreConfig.endpoint, token: StoreConfig.storefrontToken))
        }
    }

    // MARK: Reading the closet

    /// The piece with this handle, if it's for sale.
    func piece(handle: String) -> Piece? {
        byHandle[handle].map { pieces[$0] }
    }

    /// The piece with this id (its id: tag, or its handle; what Saved keeps), if it's for sale.
    func piece(id: String) -> Piece? {
        byID[id].map { pieces[$0] }
    }

    /// How many pieces for sale a department has, or one of its categories (the home page's View all, "117 pieces").
    func count(dept: Dept, cat: String? = nil) -> Int {
        pieces.reduce(0) { n, p in n + (p.dept == dept && (cat == nil || p.cat == cat) ? 1 : 0) }
    }

    /// Everything a piece's page shows, a sold piece's too (its page says it has sold); nil when the store has no
    /// such product. Throws when the store can't be reached.
    func productDetail(handle: String) async throws -> ProductDetail? {
        let record = try await Self.productRecord(source, handle: handle, records: records)
        return record.flatMap(toProductDetail)
    }

    // MARK: Loading

    /// The first load: fetches the closet unless it's already here (or on its way, which it then waits for).
    func load() async {
        if state == .loaded { return }
        await fetch()
    }

    /// Fetches the closet again (pull to refresh). A fetch already under way counts: it's waited for, not repeated.
    func refresh() async {
        await fetch()
    }

    /// Tell the closet when the app goes away and comes back (from the scene's `scenePhase`): coming back after
    /// `comeBackAfter` or more, or after a load that failed, fetches it again (the fetch it starts, if any).
    @discardableResult
    func scenePhaseChanged(to phase: ScenePhase, at now: Date = .now) -> Task<Void, Never>? {
        switch phase {
        case .background:
            if awaySince == nil { awaySince = now }
        case .active:
            defer { awaySince = nil }
            if Self.shouldRefetch(awaySince: awaySince, now: now) || (awaySince != nil && hasFailed) {
                return Task { await refresh() }
            }
        default:
            break
        }
        return nil
    }

    private var hasFailed: Bool {
        if case .failed = state { return true }
        return false
    }

    /// The freshness rule: away a minute or more.
    nonisolated static func shouldRefetch(awaySince: Date?, now: Date) -> Bool {
        guard let awaySince else { return false }
        return now.timeIntervalSince(awaySince) >= comeBackAfter
    }

    private func fetch() async {
        if let inFlight {
            await inFlight.value
            return
        }
        let task = Task { await self.fetchNow() }
        inFlight = task
        await task.value
        inFlight = nil
    }

    private func fetchNow() async {
        if pieces.isEmpty { state = .loading }
        do {
            let snapshot = try await Self.snapshot(from: source)
            records = snapshot.records
            pieces = snapshot.pieces
            rooms = snapshot.rooms
            byHandle = Dictionary(snapshot.pieces.indices.map { (snapshot.pieces[$0].handle, $0) }, uniquingKeysWith: { a, _ in a })
            byID = Dictionary(snapshot.pieces.indices.map { (snapshot.pieces[$0].id, $0) }, uniquingKeysWith: { a, _ in a })
            loadedAt = .now
            refreshError = nil
            state = .loaded
        } catch {
            let message = CatalogError.message(for: error)
            if state == .loaded {
                refreshError = message
            } else {
                state = .failed(message)
            }
        }
    }

    /// The closet built from a source, away from the main thread (the mapping reads every photo's description).
    nonisolated struct Snapshot: Sendable {
        var records: [ProductRecord]
        var pieces: [Piece]
        var rooms: RoomPicks
    }

    @concurrent nonisolated static func snapshot(from source: any CatalogSource) async throws -> Snapshot {
        let catalog = try await source.catalog(roomCollections: Merch.homeRooms.map(\.collection))
        let pieces = closetOf(catalog.records)
        let rooms = roomPicks(catalog.roomLists, catalog.records, forSale: Set(pieces.map(\.handle)))
        return Snapshot(records: catalog.records, pieces: pieces, rooms: rooms)
    }

    @concurrent nonisolated private static func productRecord(
        _ source: any CatalogSource, handle: String, records: [ProductRecord]
    ) async throws -> ProductRecord? {
        try await source.product(handle: handle, in: records)
    }
}
