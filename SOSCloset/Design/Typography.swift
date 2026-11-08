import SwiftUI
import UIKit

/// The site's two faces (SPEC §12), bundled in Fonts/ (both SIL Open Font License) and listed in Info.plist.
/// These are PostScript names: a wrong one silently falls back to the system font, so `missing()` checks them.
nonisolated enum Typeface: Hashable, Sendable {
    /// Tenor Sans: the logo, headings and designers, in spaced capitals.
    case display
    /// Hanken Grotesk, 400–700: everything else. One file per weight: iOS doesn't find a variable font's
    /// weights by name (the Mac does), so Google Fonts' static files of each weight are bundled instead.
    case body(Weight)

    enum Weight: Hashable, Sendable {
        case regular, medium, semibold, bold
    }

    static let all: [Typeface] = [.display, .body(.regular), .body(.medium), .body(.semibold), .body(.bold)]

    var postScriptName: String {
        switch self {
        case .display: "TenorSans"
        case .body(.regular): "HankenGrotesk-Regular"
        case .body(.medium): "HankenGrotesk-Medium"
        case .body(.semibold): "HankenGrotesk-SemiBold"
        case .body(.bold): "HankenGrotesk-Bold"
        }
    }

    var familyName: String {
        switch self {
        case .display: "Tenor Sans"
        case .body: "Hanken Grotesk"
        }
    }

    /// The faces whose name doesn't find the bundled font (empty when they're all there).
    static func missing() -> [Typeface] {
        all.filter { UIFont(name: $0.postScriptName, size: 12)?.familyName != $0.familyName }
    }
}

/// A text style from the site. Sizes are the site's, in points (a CSS pixel there is a point here), and they are
/// the default size of a Dynamic Type style, growing with the iPhone's text size (APP-SPEC §6).
nonisolated struct TextStyle: Hashable, Sendable {
    var face: Typeface
    var size: CGFloat
    /// Letter spacing in em, as the site's CSS writes it (`letter-spacing: .16em`).
    var tracking: CGFloat = 0
    var uppercase = false
    /// Line height as a multiple of the size, as the site's CSS writes it (`line-height: 1.65`); nil keeps the font's own.
    var lineHeight: CGFloat? = nil

    /// The Dynamic Type style it grows with: the one whose default size is nearest.
    var relativeTo: Font.TextStyle {
        switch size {
        case ..<11.5: .caption2
        case ..<12.5: .caption
        case ..<13.5: .footnote
        case ..<15.5: .subheadline
        case ..<16.5: .callout
        case ..<18.5: .body
        case ..<21: .title3
        case ..<25: .title2
        case ..<31: .title
        default: .largeTitle
        }
    }
}

// The styles phase 1 shares with the site, at its phone sizes (up to 640pt wide). Each says where it comes from.
nonisolated extension TextStyle {
    /// The logo, SOS CLOSET (the site's `.logo`): 22px, .34em; 17px, .24em up to 420px wide; 16px, .2em under 375px.
    static let logo = TextStyle(face: .display, size: 22, tracking: 0.34, uppercase: true)
    static let logoPhone = TextStyle(face: .display, size: 17, tracking: 0.24, uppercase: true)
    static let logoNarrow = TextStyle(face: .display, size: 16, tracking: 0.2, uppercase: true)
    /// The tab row on phones (SPEC §3): 11px, 500, .09em; 10.5px, .06em under 375px wide.
    static let tab = TextStyle(face: .body(.medium), size: 11, tracking: 0.09, uppercase: true)
    static let tabNarrow = TextStyle(face: .body(.medium), size: 10.5, tracking: 0.06, uppercase: true)
    /// Section labels (SPEC §12): 12px, 600, .14em, uppercase.
    static let sectionLabel = TextStyle(face: .body(.semibold), size: 12, tracking: 0.14, uppercase: true)
    /// A category heading on a department page (SPEC §7, `.tsec-go` on phones): 15px, .16em, with a hairline to the right.
    static let categoryHeading = TextStyle(face: .display, size: 15, tracking: 0.16, uppercase: true, lineHeight: 1.2)
    /// A type heading (SPEC §7, `.tsub-go`): 12.5px, 600, .12em, in ink-2, with a small chevron.
    static let typeHeading = TextStyle(face: .body(.semibold), size: 12.5, tracking: 0.12, uppercase: true)
    /// A tile's label (SPEC §7, `.cn-label` on phones): 12px, 500; 11px under 375px wide.
    static let tileLabel = TextStyle(face: .body(.medium), size: 12)
    static let tileLabelNarrow = TextStyle(face: .body(.medium), size: 11)
    /// Card text (SPEC §7): designer, name, price · size.
    /// The designer: 13px on a 17px line, stepping down to fit its card (`PieceCard`'s `FittedDesigner`).
    static let cardDesigner = TextStyle(face: .display, size: 13, tracking: 0.16, uppercase: true, lineHeight: 17.0 / 13)
    static let cardName = TextStyle(face: .body(.regular), size: 14, lineHeight: 1.4)
    /// A piece's story line in a small department's case (SPEC §7): 13px on phones, grey.
    static let cardStory = TextStyle(face: .body(.regular), size: 13, lineHeight: 1.5)
    static let cardPrice = TextStyle(face: .body(.medium), size: 15)
    static let cardSize = TextStyle(face: .body(.regular), size: 13)
    /// The place line (SPEC §3): the department in the display face, 11.5px .14em; the category and type 14px.
    static let placeDept = TextStyle(face: .display, size: 11.5, tracking: 0.14, uppercase: true)
    static let placeWord = TextStyle(face: .body(.regular), size: 14)
    static let placeWordStrong = TextStyle(face: .body(.medium), size: 14)
    /// The compact tile row's labels (SPEC §3): 11px, 500; 600 for the section in view.
    static let compactTileLabel = TextStyle(face: .body(.medium), size: 11)
    static let compactTileLabelOn = TextStyle(face: .body(.semibold), size: 11)
    // The directory (SPEC §4, the app prototype's directory).
    /// Its map: 10.5px, 500, .08em.
    static let directoryTab = TextStyle(face: .body(.medium), size: 10.5, tracking: 0.08, uppercase: true)
    /// "All of Women ›": the display face, 13px, .16em.
    static let directoryAll = TextStyle(face: .display, size: 13, tracking: 0.16, uppercase: true)
    /// A category's row: 12.5px, 600, .14em.
    static let directoryRow = TextStyle(face: .body(.semibold), size: 12.5, tracking: 0.14, uppercase: true)
    /// A type, and the house pages: 15px; All Handbags at 500.
    static let directoryItem = TextStyle(face: .body(.regular), size: 15)
    static let directoryItemStrong = TextStyle(face: .body(.medium), size: 15)
    /// The SOS Closet row: the display face, 12.5px, .16em.
    static let directoryHouse = TextStyle(face: .display, size: 12.5, tracking: 0.16, uppercase: true)
    /// The quiet line and Saved's count: 13px.
    static let directoryQuiet = TextStyle(face: .body(.regular), size: 13)
    /// A button (the site's `.btn`): 14px, 600, .04em.
    static let button = TextStyle(face: .body(.semibold), size: 14, tracking: 0.04)

    // The product page (SPEC §10; the site's 08-product.css at phone widths, as the app prototype has it).
    /// The designer leads: the display face, 28px, .16em spaced capitals, line height 1.15.
    static let productDesigner = TextStyle(face: .display, size: 28, tracking: 0.16, uppercase: true, lineHeight: 1.15)
    /// The piece's name under it, as a caption: 18px, 500, −.005em, line height 1.35.
    static let productName = TextStyle(face: .body(.medium), size: 18, tracking: -0.005, lineHeight: 1.35)
    /// The price: 22px, 600.
    static let productPrice = TextStyle(face: .body(.semibold), size: 22)
    /// The status beside it: 11px, 600, .14em spaced capitals, muted.
    static let productMarks = TextStyle(face: .body(.semibold), size: 11, tracking: 0.14, uppercase: true)
    /// The description: 15px, line height 1.65.
    static let productDescription = TextStyle(face: .body(.regular), size: 15, lineHeight: 1.65)
    /// Read more and Read less: 14px, 600, .02em, underlined.
    static let readMore = TextStyle(face: .body(.semibold), size: 14, tracking: 0.02)
    /// Add to Bag (the site's `.btn.lg`): 15px, 600, .04em.
    static let bigButton = TextStyle(face: .body(.semibold), size: 15, tracking: 0.04)
    /// The two lines under it: 13px, line height 1.5.
    static let productNote = TextStyle(face: .body(.regular), size: 13, lineHeight: 1.5)
    /// What a fold (Details, Shipping & returns) holds: 15px; the list's lines 1.45 apart, the shipping words 1.6.
    static let foldList = TextStyle(face: .body(.regular), size: 15, lineHeight: 1.45)
    static let foldText = TextStyle(face: .body(.regular), size: 15, lineHeight: 1.6)
    /// The photo counter (2 / 7): 12px, .08em.
    static let photoCounter = TextStyle(face: .body(.regular), size: 12, tracking: 0.08)
    /// "Labels & markings": 11px, 600, .14em spaced capitals, muted.
    static let proofLabel = TextStyle(face: .body(.semibold), size: 11, tracking: 0.14, uppercase: true)
    /// A size to choose (the site's `.fchip`): 14px.
    static let sizeChip = TextStyle(face: .body(.regular), size: 14)
    /// A message under Add to Bag ("This piece has sold."): 14px, line height 1.5.
    static let productMessage = TextStyle(face: .body(.regular), size: 14, lineHeight: 1.5)

    // The bag (SPEC §11; the app prototype's Bag).
    /// "Bag": the display face, 25px, .1em spaced capitals.
    static let bagTitle = TextStyle(face: .display, size: 25, tracking: 0.1, uppercase: true)
    /// Remove: 13px, underlined.
    static let bagRemove = TextStyle(face: .body(.regular), size: 13)
    /// The subtotal's row: 16px (its amount 600); shipping's row 14px.
    static let bagSubtotal = TextStyle(face: .body(.regular), size: 16)
    static let bagSubtotalAmount = TextStyle(face: .body(.semibold), size: 16)
    static let bagRow = TextStyle(face: .body(.regular), size: 14)
    /// "Your bag is empty.": 17px, 500.
    static let bagEmpty = TextStyle(face: .body(.medium), size: 17)
    /// Continue shopping: 13px, 600, .04em.
    static let smallButton = TextStyle(face: .body(.semibold), size: 13, tracking: 0.04)
    /// Saved's hint when it's empty ("Tap the heart on any piece to keep it here."): 15px, muted.
    static let savedHint = TextStyle(face: .body(.regular), size: 15, lineHeight: 1.5)

    // Home (SPEC §11a; the site's 05-home.css at phone widths, as the app prototype has them).
    /// "Beautiful things.": the display face, 40px, .01em, line height 1.06.
    static let homeTitle = TextStyle(face: .display, size: 40, tracking: 0.01, lineHeight: 1.06)
    /// "Louis Vuitton, Gucci, Hermès and more.": 15px, line height 1.6, in ink-2.
    static let homeLine = TextStyle(face: .body(.regular), size: 15, lineHeight: 1.6)
    /// Shop women and Shop men: 12px, 600, .16em spaced capitals.
    static let homeButton = TextStyle(face: .body(.semibold), size: 12, tracking: 0.16, uppercase: true)
    /// A credit's designer, under a bag on the turntable and under a piece in a room: 10px, .15em spaced capitals.
    static let creditDesigner = TextStyle(face: .display, size: 10, tracking: 0.15, uppercase: true)
    /// A credit's name and price: 11px (muted, the name in ink-2).
    static let creditLine = TextStyle(face: .body(.regular), size: 11)
    /// A room's title, which is its link: 13px, .22em spaced capitals.
    static let roomTitle = TextStyle(face: .display, size: 13, tracking: 0.22, uppercase: true, lineHeight: 1.2)
    /// The service notes at the foot of Home: the titles 13px .2em spaced capitals, the words and links 16px.
    static let noteTitle = TextStyle(face: .display, size: 13, tracking: 0.2, uppercase: true)
    static let noteText = TextStyle(face: .body(.regular), size: 16, lineHeight: 1.5)
    static let noteLink = TextStyle(face: .body(.regular), size: 16)
    /// The footer's disclosure (SPEC §2): 12px, line height 1.5, muted.
    static let disclosure = TextStyle(face: .body(.regular), size: 12, lineHeight: 1.5)
}

extension TextStyle {
    /// The size the font has at a text size (Dynamic Type), for measuring a line before it's drawn.
    func scaledSize(at dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(dynamicTypeSize))
        return UIFontMetrics(forTextStyle: relativeTo.uiTextStyle).scaledValue(for: size, compatibleWith: traits)
    }
}

extension View {
    /// Sets a site text style: its face, its size growing with Dynamic Type, its letter spacing and line height.
    func textStyle(_ style: TextStyle) -> some View {
        modifier(TextStyleModifier(style: style))
    }
}

private struct TextStyleModifier: ViewModifier {
    let style: TextStyle
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let size = scaledSize
        content
            .font(.custom(style.face.postScriptName, size: style.size, relativeTo: style.relativeTo))
            .tracking(style.tracking * size)
            .textCase(style.uppercase ? .uppercase : nil)
            .lineSpacing(lineSpacing(at: size))
            .padding(.vertical, halfLeading(at: size))
    }

    /// CSS centres each line in its line box, adding (or, under the font's own height, taking away) half the difference
    /// above the first line and below the last; SwiftUI doesn't, so the text's frame is matched to the CSS line box.
    private func halfLeading(at size: CGFloat) -> CGFloat {
        guard let multiple = style.lineHeight, let font = UIFont(name: style.face.postScriptName, size: size) else { return 0 }
        return (size * multiple - font.lineHeight) / 2
    }

    /// The size the font has at the current text size, so letter spacing and line height grow with it.
    private var scaledSize: CGFloat { style.scaledSize(at: dynamicTypeSize) }

    /// CSS sets a line's whole height; SwiftUI adds space between lines, so it's the difference.
    private func lineSpacing(at size: CGFloat) -> CGFloat {
        guard let multiple = style.lineHeight, let font = UIFont(name: style.face.postScriptName, size: size) else { return 0 }
        return max(0, size * multiple - font.lineHeight)
    }
}

extension Font.TextStyle {
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .subheadline: .subheadline
        case .body: .body
        case .callout: .callout
        case .footnote: .footnote
        case .caption: .caption1
        case .caption2: .caption2
        @unknown default: .body
        }
    }
}
