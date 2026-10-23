import CoreText
import SwiftUI
import Testing
import UIKit
@testable import SOSCloset

/// The fonts are bundled and found by name (a wrong PostScript name silently falls back to the system font).
struct FontTests {
    @Test func everyFaceLoads() {
        #expect(Typeface.missing().isEmpty)
    }

    /// Each weight is its own face, heavier than the one before (CoreText's weight trait: 0 regular, 0.4 bold).
    @Test func hankenWeightsAreTheirOwnFaces() throws {
        let weights = try [Typeface.Weight.regular, .medium, .semibold, .bold].map { weight in
            let font = try #require(UIFont(name: Typeface.body(weight).postScriptName, size: 12))
            let traits = CTFontCopyTraits(font as CTFont) as NSDictionary
            return try #require(traits[kCTFontWeightTrait] as? Double)
        }
        #expect(weights == weights.sorted() && Set(weights).count == 4)
    }
}

/// Text styles grow with the Dynamic Type style whose default size is nearest the site's size.
struct TextStyleTests {
    @Test func growsWithTheNearestStyle() {
        #expect(TextStyle.cardDesigner.relativeTo == .footnote) // 13
        #expect(TextStyle.cardName.relativeTo == .subheadline) // 14
        #expect(TextStyle.cardPrice.relativeTo == .subheadline) // 15
        #expect(TextStyle.tab.relativeTo == .caption2) // 11
        #expect(TextStyle.tileLabel.relativeTo == .caption) // 12
        #expect(TextStyle.logo.relativeTo == .title2) // 22
    }

    @Test func gutterFollowsTheWindowWidth() {
        #expect(Layout.gutter(forWidth: 390) == 16)
        #expect(Layout.gutter(forWidth: 640) == 16)
        #expect(Layout.gutter(forWidth: 641) == 24)
    }
}
