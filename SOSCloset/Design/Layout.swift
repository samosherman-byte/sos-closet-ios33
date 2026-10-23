import SwiftUI

/// The site's layout and motion settings (SPEC §12), by name. Layouts follow the window's width, not the device's
/// name: iPhone apps can be resized on iOS 27 (APP-SPEC §1).
nonisolated enum Layout {
    /// Up to this width the site's phone layout applies: two across, edge to edge, and the photo size standard's
    /// numbers as they are (wider adds `--fk`).
    static let phoneMaxWidth: CGFloat = 640
    /// The site's breakpoint for its narrowest phones: shorter tab labels, smaller tile labels and logo.
    static let narrowWidth: CGFloat = 375
    /// The page's side margin: 16pt on phones, 24pt wider.
    static func gutter(forWidth width: CGFloat) -> CGFloat {
        width <= phoneMaxWidth ? 16 : 24
    }
}

/// The site's easing curves (SPEC §12). Every animation has a Reduce Motion fallback (APP-SPEC §6).
nonisolated enum Motion {
    /// `--ease`
    static func ease(_ duration: Double) -> Animation { .timingCurve(0.22, 0.61, 0.36, 1, duration: duration) }
    /// `--ease-out`
    static func easeOut(_ duration: Double) -> Animation { .timingCurve(0.16, 1, 0.3, 1, duration: duration) }
    /// Swipes and glides.
    static func glide(_ duration: Double) -> Animation { .timingCurve(0.2, 0.8, 0.2, 1, duration: duration) }
    /// The phone page push and the photo's glide into a piece (560ms there): one decelerating move, no bounce.
    static func push(_ duration: Double) -> Animation { .timingCurve(0.32, 0.72, 0, 1, duration: duration) }
    /// The one curve allowed a slight overshoot: glass appearing, stretching and pressing (custom glass only;
    /// the system glass moves on its own).
    static func glassSpring(_ duration: Double) -> Animation { .timingCurve(0.34, 1.45, 0.55, 1, duration: duration) }
}
