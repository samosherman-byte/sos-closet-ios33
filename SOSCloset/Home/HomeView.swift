import SwiftUI

/// Home, as on soscloset.com (APP-SPEC §3.4): the opening, the turntable of three bags, the four rooms and the service
/// notes, under the header with no tab underlined. Empty until the `home` step.
struct HomeView: View {
    var body: some View {
        HeaderPage(current: nil) { _ in
            Color.paper
                .frame(height: 1)
                .frame(maxWidth: .infinity)
                .accessibilityHidden(true)
        }
    }
}
