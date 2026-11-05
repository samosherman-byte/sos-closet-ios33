import SwiftUI

/// The bag (APP-SPEC §3.7), under the top row alone. Empty until the `bag/checkout` step.
struct BagView: View {
    var body: some View {
        HeaderPage(showsMap: false) { _ in
            Color.paper.frame(height: 1).frame(maxWidth: .infinity).accessibilityHidden(true)
        }
    }
}
