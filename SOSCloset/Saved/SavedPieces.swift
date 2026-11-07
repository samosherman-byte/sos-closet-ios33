import Foundation
import Observation

/// The pieces the shopper has hearted (APP-SPEC §3.8): kept on the phone, as the site keeps them in the browser, by
/// the piece's id (its `id:` tag, or its handle), so the ids are the site's. The Saved page lists the ones still for
/// sale (it comes with `saved`); cards and the directory's Saved count read them now.
@MainActor @Observable final class SavedPieces {
    private(set) var ids: Set<String>

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let key: String

    init(defaults: UserDefaults = .standard, key: String = "SOSSaved") {
        self.defaults = defaults
        self.key = key
        ids = Set(defaults.stringArray(forKey: key) ?? [])
    }

    func contains(_ piece: Piece) -> Bool { ids.contains(piece.id) }

    func toggle(_ piece: Piece) {
        if ids.contains(piece.id) { ids.remove(piece.id) } else { ids.insert(piece.id) }
        defaults.set(ids.sorted(), forKey: key)
    }

    /// How many hearted pieces are still for sale (sold ones drop out).
    func count(in closet: Closet) -> Int {
        ids.reduce(0) { n, id in n + (closet.piece(id: id) == nil ? 0 : 1) }
    }
}
