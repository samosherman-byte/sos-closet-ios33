import SwiftUI

/// Saved: the hearted pieces still for sale (APP-SPEC §3.8), under the top row alone. Empty until the `saved` step.
struct SavedView: View {
    var body: some View {
        HeaderPage(showsMap: false) { _ in
            Color.paper.frame(height: 1).frame(maxWidth: .infinity).accessibilityHidden(true)
        }
    }
}
