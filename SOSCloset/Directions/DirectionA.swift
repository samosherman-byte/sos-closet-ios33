import SwiftUI

/// Direction A (APP-SPEC §7): the site's header, natively. At the top of a page the classic flat header: Menu, the
/// logo and Bag as plain icons on white, and the tab row between hairlines. Scrolling down, the tabs dematerialize and
/// Menu and Bag float in Liquid Glass over the pieces, with the system scroll edge effect behind them; scrolling up
/// brings the flat header back. The places sit side by side: a tab glides the page sideways, and a swipe moves along
/// the map under the finger.
struct DirectionA: View {
    @State private var current: Place = Demo.page ?? .shopAll
    @State private var position: CGFloat = CGFloat((Demo.page ?? .shopAll).rawValue)
    @State private var tabs = TabsVisibility()
    @State private var menuOpen = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let topRowHeight: CGFloat = 56
    private let tabRowHeight: CGFloat = 44

    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            ZStack(alignment: .top) {
                PlacePager(places: [.home] + Place.tabs, current: $current, position: $position,
                           barHeight: topRowHeight, topPadding: tabRowHeight) { place, old, new in
                    tabs.scrolled(from: old, to: new, threshold: place.isDepartment ? 120 : 160)
                }
                header(width: width)
            }
        }
        .background(.paper)
        .onChange(of: current) { tabs.show() }
        .sensoryFeedback(.selection, trigger: current)
        .sheet(isPresented: $menuOpen) { InterimMenu() }
    }

    private func header(width: CGFloat) -> some View {
        let floating = !tabs.shown
        return VStack(spacing: 0) {
            HStack(spacing: 0) {
                CircleButton(label: "Menu", glass: floating, action: { menuOpen = true }) { MenuIcon() }
                Spacer(minLength: 8)
                Button { current = .home } label: { Logo(width: width) }
                    .buttonStyle(.plain)
                    .accessibilityLabel("SOS Closet home")
                Spacer(minLength: 8)
                CircleButton(label: "Bag", glass: floating, badge: 0, action: {}) {
                    Image(systemName: "bag").font(.system(size: 18, weight: .regular))
                }
            }
            .padding(.horizontal, 12)
            .frame(height: topRowHeight)

            TabRow(width: width, position: position) { current = $0 }
                .overlay(alignment: .top) { Rectangle().fill(.lineSoft).frame(height: 1) }
                .overlay(alignment: .bottom) { Rectangle().fill(.line).frame(height: 1) }
                // The tabs dematerialize: fade, shrink to 94% and blur (Reduce Motion: fade only).
                .opacity(floating ? 0 : 1)
                .scaleEffect(floating && !reduceMotion ? 0.94 : 1)
                .blur(radius: floating && !reduceMotion ? 6 : 0)
                .allowsHitTesting(!floating)
                .accessibilityHidden(floating)
        }
        .background(alignment: .top) {
            // At rest the header is the classic flat white band; once the tabs make way it's gone, and the page's
            // scroll edge effect shows behind the floating controls instead.
            Rectangle().fill(.paper).ignoresSafeArea(edges: .top)
                .opacity(floating ? 0 : 1)
        }
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : Motion.ease(0.32), value: floating)
    }
}

/// Whether direction A's tabs are showing (SPEC §3): scrolling down past the start of the pieces they make way;
/// scrolling up more than ~8pt, or reaching the top, brings them back.
@Observable final class TabsVisibility {
    private(set) var shown = true
    private var upward: CGFloat = 0

    func scrolled(from old: CGFloat, to new: CGFloat, threshold: CGFloat) {
        if new <= threshold {
            show()
        } else if new > old + 0.5 {
            upward = 0
            shown = false
        } else if new < old {
            upward += old - new
            if upward > 8 { shown = true }
        }
    }

    func show() {
        upward = 0
        shown = true
    }
}

extension Place {
    var isDepartment: Bool { Place.departments.contains(self) }
}

/// The logo, SOS CLOSET, at the site's sizes for the window's width (the site's `.logo`). The site pads its left by
/// the letter spacing so the letters sit centered; the same here.
struct Logo: View {
    let width: CGFloat

    var body: some View {
        let style: TextStyle = width < Layout.narrowWidth ? .logoNarrow : width <= 420 ? .logoPhone : .logo
        Text("SOS Closet")
            .textStyle(style)
            .foregroundStyle(.ink)
            .padding(.leading, style.tracking * style.size)
            .fixedSize()
    }
}

/// Menu's icon: two short lines, as on the site (18 × 10pt, 1.5pt thick).
struct MenuIcon: View {
    var body: some View {
        VStack(spacing: 5) {
            Rectangle().frame(width: 18, height: 1.5)
            Rectangle().frame(width: 18, height: 1.5)
        }
    }
}

/// A round icon control: plain ink at rest; regular, interactive Liquid Glass once it floats over the page.
struct CircleButton<Icon: View>: View {
    let label: String
    var glass = false
    var badge = 0
    let action: () -> Void
    @ViewBuilder let icon: () -> Icon

    var body: some View {
        Button(action: action) {
            icon()
                .foregroundStyle(.ink)
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .glassEffect(glass ? .regular.interactive() : .identity, in: .circle)
        .overlay(alignment: .topTrailing) {
            if badge > 0 {
                Text("\(badge)")
                    .textStyle(TextStyle(face: .body(.semibold), size: 10))
                    .foregroundStyle(.paper)
                    .padding(.horizontal, 4)
                    .frame(minWidth: 16, minHeight: 16)
                    .background(Capsule().fill(.ink))
                    .offset(x: -3, y: 6)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(badge > 0 ? "\(label), \(badge) \(badge == 1 ? "piece" : "pieces")" : label)
    }
}

/// Menu in phase 1 (APP-SPEC §2): a short interim list, Saved with its count and the house's contact line, until the
/// directory exists. A sheet, the iPhone's panel for a short task.
struct InterimMenu: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            menuRow(systemName: "heart", title: "Saved", detail: "0")
            Divider().overlay(Color.line)
            Link(destination: URL(string: "mailto:soscloset33@gmail.com")!) {
                menuRow(systemName: "envelope", title: "Ask SOS Closet", detail: "soscloset33@gmail.com")
            }
            Divider().overlay(Color.line)
            Link(destination: URL(string: "https://www.instagram.com/soscloset33/")!) {
                menuRow(systemName: "camera", title: "Follow the closet", detail: "@SOSCLOSET33")
            }
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 28)
        .presentationDetents([.height(260)])
        .presentationDragIndicator(.visible)
    }

    private func menuRow(systemName: String, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemName).font(.system(size: 17)).frame(width: 24)
            Text(title).textStyle(TextStyle(face: .body(.medium), size: 16))
            Spacer()
            Text(detail).textStyle(.cardSize).foregroundStyle(.muted)
        }
        .foregroundStyle(.ink)
        .frame(minHeight: 56)
        .contentShape(Rectangle())
    }
}
