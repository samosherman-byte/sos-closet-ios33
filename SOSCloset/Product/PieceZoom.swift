import SwiftUI

// Opening a piece (APP-SPEC §3.6, §4; SPEC §5): the piece you tapped becomes the page. The app uses the system's zoom
// transition, from the card's photo into the product page, and back by Back, the edge swipe or pulling the page down:
// one decelerating move, interactive (the page can be grabbed mid-move), and the page you came from is kept exactly as
// it was. Reduce Motion: no zoom.

extension EnvironmentValues {
    /// The namespace the cards of this tab's stack zoom out of (nil outside a stack that opens pieces).
    @Entry var pieceZoom: Namespace.ID? = nil
    /// Where a card sits, so the same piece's card in two places (a department and a piece's "You may also like")
    /// zooms out of the one that was tapped.
    @Entry var zoomContext = "page"
}

extension View {
    /// A stack's piece pages: each zooms out of its card's photo.
    func pieceDestinations() -> some View {
        modifier(PieceDestinations())
    }

    /// The card's photo the piece's page zooms out of and back into.
    @ViewBuilder func zoomSource(_ id: String, in namespace: Namespace.ID?) -> some View {
        if let namespace {
            matchedTransitionSource(id: id, in: namespace) { $0.background(.paper) }
        } else {
            self
        }
    }
}

private struct PieceDestinations: ViewModifier {
    @Namespace private var zoom
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .environment(\.pieceZoom, zoom)
            .navigationDestination(for: PieceRoute.self) { route in
                transition(ProductPage(route: route).environment(\.pieceZoom, zoom), route)
            }
    }

    /// Zooming out of the card that was tapped; with no card, or with Reduce Motion, the system's own push (a
    /// cross-fade on iOS 27 with Reduce Motion).
    @ViewBuilder private func transition(_ page: some View, _ route: PieceRoute) -> some View {
        if let id = route.zoomID, !reduceMotion {
            page.navigationTransition(.zoom(sourceID: id, in: zoom))
        } else if reduceMotion, #available(iOS 27, *) {
            page.navigationTransition(.crossFade)
        } else {
            page
        }
    }
}
