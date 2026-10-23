import SwiftUI

// The site's colors (SPEC §12; the tokens in the site's app/styles/00-base.css), with the same names.
// Light appearance only, like the site: every color is set explicitly.
extension ShapeStyle where Self == Color {
    static var paper: Color { Color(hex: 0xFFFFFF) }
    static var ink: Color { Color(hex: 0x111111) }
    static var ink2: Color { Color(hex: 0x3A3A38) }
    static var ink3: Color { Color(hex: 0x2A2A28) }
    static var muted: Color { Color(hex: 0x6E6E6B) }
    /// The ground a photo shows on while it loads (cards without photo size numbers).
    static var stone: Color { Color(hex: 0xF3F3F1) }
    static var stone2: Color { Color(hex: 0xECEBE8) }
    static var line: Color { Color(hex: 0xE6E6E3) }
    static var lineSoft: Color { Color(hex: 0xF0F0EE) }
    static var lineStrong: Color { Color(hex: 0xC9C9C5) }
    static var link: Color { Color(hex: 0x1F4F7A) }
    static var linkHover: Color { Color(hex: 0x0F2F4D) }
    static var night: Color { Color(hex: 0x111111) }
    static var nightText: Color { Color(hex: 0xD9D9D6) }
    static var nightMuted: Color { Color(hex: 0xA9A9A5) }
    static var nightLine: Color { Color(hex: 0x2A2A28) }
    /// The Latest's "New" (desktop only on the site).
    static var accent: Color { Color(hex: 0xB4441B) }
    static var scrim: Color { Color(hex: 0x111111, opacity: 0.34) }
}

extension Color {
    init(hex: UInt32, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
