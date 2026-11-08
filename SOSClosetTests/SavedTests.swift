import Foundation
import Testing
@testable import SOSCloset

// Saved (APP-SPEC §3.8; the site's saved.tsx and app/lib/saved.ts): hearts kept on the phone by the piece's id, and
// the Saved page listing the hearted pieces still for sale, in the closet's order.

@MainActor
@Suite("Saved")
struct SavedTests {
    private func fresh() -> (UserDefaults, String) {
        let name = "SOSSavedTests-\(UUID().uuidString)"
        return (UserDefaults(suiteName: name)!, name)
    }

    @Test func aHeartIsKeptOnThePhoneByThePiecesId() {
        let (defaults, _) = fresh()
        let saved = SavedPieces(defaults: defaults, key: "SOSSaved")
        let jackie = Piece.stub("jackie", handle: "gucci-jackie-1961-medium-tote")
        #expect(!saved.contains(jackie))
        saved.toggle(jackie)
        #expect(saved.contains(jackie))
        // Kept by its id (the site's ids), not its handle, and there the next time the app opens.
        #expect(defaults.stringArray(forKey: "SOSSaved") == ["jackie"])
        #expect(SavedPieces(defaults: defaults, key: "SOSSaved").contains(jackie))
        saved.toggle(jackie)
        #expect(!saved.contains(jackie))
        #expect(defaults.stringArray(forKey: "SOSSaved") == [])
    }

    @Test func theListIsTheHeartedPiecesStillForSaleInTheClosetsOrder() {
        let closet = ["a", "b", "c", "d"].map { Piece.stub($0) }
        // Hearted in another order, and one that has sold since (it isn't in the closet).
        let list = savedList(closet, ids: ["d", "sold-one", "b"])
        #expect(list.map(\.id) == ["b", "d"])
        #expect(savedList(closet, ids: []).isEmpty)
    }

    @Test(.enabled(if: SampleFiles.available, "The sample store isn't here: run tools/sync-sample-store.sh"))
    func thePrototypesSavedPiecesAreInTheSampleStore() {
        let ids: Set<String> = ["herm-blue", "c154", "choo", "arabia"]
        let list = savedList(SampleFiles.pieces, ids: ids)
        #expect(Set(list.map(\.id)) == ids)
        let order = list.map { p in SampleFiles.pieces.firstIndex(of: p)! }
        #expect(order == order.sorted())
    }
}
