import SwiftUI
import UIKit

/// Where you are, in words: the department, then the section in view and the type within it (SPEC §3).
struct PlaceWords: Equatable {
    var dept: String
    var section: String
    var type: String

    /// For screen readers: "Women, Clothing, Knitwear. Show every department and category".
    var label: String {
        [dept, section, type].filter { !$0.isEmpty }.joined(separator: ", ") + ". Show every department and category"
    }
}

/// The place line (SPEC §3, "The key says where you are"): when the tabs make way, the key becomes one line in Liquid
/// Glass, WOMEN / Clothing / Knitwear, ended by a round ink chevron. The level you're on is the strongest word; the
/// words roll as headings reach the top. The whole line is one button and opens the directory.
struct PlaceLine: View {
    let words: PlaceWords
    let rollFrom: Edge
    /// The room the words have: the line's widest (the screen less its margins) less its padding and the chevron.
    let room: CGFloat
    /// On a piece's page at rest the line sits flat on the page (white, only the glass's hairline rim; SPEC §10, "Flat
    /// at rest"); it turns to glass as it floats up into the top row.
    var flat = false
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// The padding and the chevron: 16pt before the words, 8pt and the 28pt circle after them, 7pt to the end.
    static let chrome: CGFloat = 16 + 8 + 28 + 7

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                let sectionStyle: TextStyle = words.type.isEmpty ? .placeWordStrong : .placeWord
                let fit = PlaceFit.fit(
                    dept: PlaceFit.width(words.dept, .placeDept, dynamicTypeSize),
                    section: PlaceFit.width(words.section, sectionStyle, dynamicTypeSize),
                    type: PlaceFit.width(words.type, .placeWordStrong, dynamicTypeSize),
                    room: room)
                Text(words.dept)
                    .textStyle(.placeDept)
                    .foregroundStyle(.ink)
                    .lineLimit(1)
                    .fixedSize()
                if let w = fit.section {
                    Slash()
                    RollingWord(
                        text: words.section, style: sectionStyle, color: words.type.isEmpty ? .ink : .muted,
                        rollFrom: rollFrom
                    )
                    .frame(maxWidth: w == .infinity ? nil : w, alignment: .leading)
                    .fixedSize(horizontal: w == .infinity, vertical: false)
                }
                if let w = fit.type {
                    Slash()
                    RollingWord(text: words.type, style: .placeWordStrong, color: .ink, rollFrom: rollFrom)
                        .frame(maxWidth: w == .infinity ? nil : w, alignment: .leading)
                        .fixedSize(horizontal: w == .infinity, vertical: false)
                }
                ChevronKey()
                    .padding(.leading, 8)
            }
            .padding(.leading, 16)
            .padding(.trailing, 7)
            .frame(height: 42)
            .flatOrGlass(flat, in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(PressChevron())
        .accessibilityLabel(words.label)
        .accessibilityShowsLargeContentViewer {
            Text([words.dept, words.section, words.type].filter { !$0.isEmpty }.joined(separator: " / "))
        }
        .animation(reduceMotion ? nil : Motion.easeOut(0.42), value: words)
    }
}

extension View {
    /// A control of the floating navigation, flat on the page (`flat`: white with the glass's hairline rim and edge,
    /// no shadow, so the white around it runs into the photo's white; SPEC §10) or in Liquid Glass over it. With
    /// Increase Contrast the flat rim is a solid ink line (APP-SPEC §6); the glass adapts by itself.
    func flatOrGlass<S: Shape>(_ flat: Bool, in shape: S) -> some View {
        modifier(FlatOrGlass(flat: flat, shape: shape))
    }
}

private struct FlatOrGlass<S: Shape>: ViewModifier {
    let flat: Bool
    let shape: S

    @Environment(\.colorSchemeContrast) private var contrast

    func body(content: Content) -> some View {
        let strong = contrast == .increased
        content
            .background {
                shape.fill(.paper)
                    .overlay {
                        shape.stroke(strong ? Color.ink : Color.ink.opacity(0.16), lineWidth: strong ? 1 : 0.75)
                    }
                    .opacity(flat ? 1 : 0)
            }
            .glassEffect(flat ? .identity : .regular.interactive(), in: shape)
    }
}

/// The thin slanted hairline between the words (1 × 14pt, `line-strong`, 18°), 10pt either side. Drawn as ink at 22%,
/// which is `line-strong` on white, so it stays as visible over the glass when darker photos pass behind it.
private struct Slash: View {
    var body: some View {
        Rectangle()
            .fill(Color.ink.opacity(0.22))
            .frame(width: 1, height: 14)
            .rotationEffect(.degrees(18))
            .padding(.horizontal, 10)
            .accessibilityHidden(true)
    }
}

/// A word that rolls to the next as its heading reaches the line: going down the page the new word comes up from below
/// (~420ms in, ~280ms out), going back up it comes down from above. Reduce Motion: it fades.
private struct RollingWord: View {
    let text: String
    let style: TextStyle
    let color: Color
    let rollFrom: Edge

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .leading) {
            Text(text)
                .textStyle(style)
                .foregroundStyle(color)
                .lineLimit(1)
                .truncationMode(.tail)
                .id(text)
                .transition(roll)
        }
        .clipped()
    }

    private var roll: AnyTransition {
        if reduceMotion { return .opacity }
        let away: Edge = rollFrom == .bottom ? .top : .bottom
        return .asymmetric(
            insertion: .move(edge: rollFrom).combined(with: .opacity).animation(Motion.easeOut(0.42)),
            removal: .move(edge: away).combined(with: .opacity).animation(.easeIn(duration: 0.28)))
    }
}

/// The round ink chevron at the line's end (28pt on phones; a white down-chevron), its own small solid button
/// within the line: pressing the line presses it to 90% (150ms).
private struct ChevronKey: View {
    @Environment(\.linePressed) private var pressed

    var body: some View {
        Circle()
            .fill(.ink)
            .frame(width: 28, height: 28)
            .overlay {
                Polyline(box: CGSize(width: 24, height: 24), points: [(6, 9.5), (12, 15.5), (18, 9.5)])
                    .stroke(.white, style: StrokeStyle(lineWidth: 1.3, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 12)
            }
            .scaleEffect(pressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.15), value: pressed)
            .accessibilityHidden(true)
    }
}

private struct PressChevron: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label.environment(\.linePressed, configuration.isPressed && !reduceMotion)
    }
}

extension EnvironmentValues {
    @Entry var linePressed = false
}

/// How the words share the room there is (SPEC §3, "Longer than the room"): the type gives way first, with an
/// ellipsis, and steps out entirely rather than show a sliver (under ~44pt); then the section, with an ellipsis; the
/// department is never cut. Nil: the word (and its slash) steps out; infinity: it shows whole.
nonisolated enum PlaceFit {
    static let sliver: CGFloat = 44
    /// A slash and the room either side of it.
    static let slash: CGFloat = 21

    static func fit(dept: CGFloat, section: CGFloat, type: CGFloat, room: CGFloat) -> (section: CGFloat?, type: CGFloat?) {
        let hasSection = section > 0.5
        let hasType = hasSection && type > 0.5
        var total = dept
        if hasSection { total += slash + section }
        if hasType { total += slash + type }
        if total <= room { return (hasSection ? .infinity : nil, hasType ? .infinity : nil) }
        if hasType {
            let left = room - (dept + slash + section + slash)
            if left >= sliver { return (.infinity, left) }
        }
        guard hasSection else { return (nil, nil) }
        let left = room - (dept + slash)
        return left >= sliver ? (min(section, left), nil) : (nil, nil)
    }

    /// A word's width in a text style at the current text size.
    @MainActor static func width(_ text: String, _ style: TextStyle, _ dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        guard !text.isEmpty else { return 0 }
        let size = style.scaledSize(at: dynamicTypeSize)
        guard let font = UIFont(name: style.face.postScriptName, size: size) else { return 0 }
        let words = style.uppercase ? text.uppercased() : text
        return ceil(NSAttributedString(string: words, attributes: [.font: font, .kern: style.tracking * size]).size().width)
    }
}
