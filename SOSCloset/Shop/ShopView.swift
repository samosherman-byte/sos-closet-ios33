import SwiftUI

/// Shop: Shop All and the three departments, one page each, under the header with their tab underlined (APP-SPEC
/// §3.2, §7). Moving between them pushes the new page in from its side of the map (SPEC §1.1, §5). The pages
/// themselves come with `browse/departments`; for now each is empty.
struct ShopView: View {
    @Environment(AppState.self) private var app
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HeaderPage(current: app.place) { width in
            ZStack {
                ShopPage(place: app.place)
                    .id(app.place)
                    .transition(pageTransition)
            }
            .animation(reduceMotion ? .easeOut(duration: 0.2) : Motion.push(0.56), value: app.place)
        }
    }

    /// Along the map: a page further right comes in from the right and the old one leaves to the left, and back the
    /// other way. Reduce Motion: a fade.
    private var pageTransition: AnyTransition {
        if reduceMotion { return .opacity }
        return app.direction > 0
            ? .asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading))
            : .asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing))
    }
}

/// One Shop page (empty until `browse/departments`).
private struct ShopPage: View {
    let place: ShopPlace

    var body: some View {
        Color.paper
            .frame(height: 1)
            .frame(maxWidth: .infinity)
            .accessibilityHidden(true)
    }
}
