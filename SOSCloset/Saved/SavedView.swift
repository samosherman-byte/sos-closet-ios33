import SwiftUI

/// Saved (APP-SPEC §3.8; SPEC §11; the app prototype's Saved), under the top row alone: SAVED, then the hearted pieces
/// still for sale as cards, two across, edge to edge, in the closet's order (sold ones drop out). Un-hearting a card
/// takes it off the page. With nothing saved, one line, how to save, and the way back to the pieces. Hearts are kept
/// on the phone, as the site keeps them in the browser.
struct SavedView: View {
    @Environment(SavedPieces.self) private var saved
    @Environment(Closet.self) private var closet
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HeaderPage(showsMap: false, refresh: { await closet.refresh() }) { width in
            let list = savedList(closet.pieces, ids: saved.ids)
            VStack(spacing: 0) {
                Text("Saved")
                    .textStyle(.bagTitle)
                    .foregroundStyle(.ink)
                    .padding(.leading, TextStyle.bagTitle.tracking * TextStyle.bagTitle.size)
                    .frame(maxWidth: .infinity)
                    .accessibilityAddTraits(.isHeader)
                    .padding(.bottom, 24)
                if list.isEmpty {
                    if closet.state != .loading { empty }
                } else {
                    PieceGrid(pieces: list, width: width)
                        .environment(\.zoomContext, "saved")
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Saved pieces")
                }
            }
            .padding(.top, 24)
            .padding(.bottom, 56)
            .frame(width: width)
            .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.easeOut(0.45), value: list.map(\.id))
        }
    }

    /// Nothing saved yet: how to save, and the way back to the pieces.
    private var empty: some View {
        VStack(spacing: 12) {
            Text("Nothing saved yet.")
                .textStyle(.bagEmpty)
                .foregroundStyle(.ink)
            Text("Tap the heart on any piece to keep it here.")
                .textStyle(.savedHint)
                .foregroundStyle(.muted)
                .multilineTextAlignment(.center)
            Button { app.tab = .shop } label: {
                Text("Continue shopping")
                    .textStyle(.smallButton)
                    .foregroundStyle(.paper)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 8)
                    .frame(minHeight: 48)
                    .background(.ink)
                    .contentShape(.rect)
            }
            .buttonStyle(Dimmed())
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}
