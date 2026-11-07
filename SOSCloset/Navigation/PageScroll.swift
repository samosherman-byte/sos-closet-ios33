import SwiftUI

/// What the header shows as a page scrolls (SPEC §3): at rest the flat header and the tab row; heading down past the
/// threshold the tabs make way (and on a Shop page the place line comes); heading back up mid-page the tabs come back
/// (with the compact tile row on a page with a tile row).
enum HeaderMode: Equatable, Sendable {
    case rest, down, up
}

/// One page's scroll, for its header and its own moves (SPEC §3; the app prototype's `onScroll`): the mode, the
/// section and type whose headings have reached the top (the place line's words, the compact row's underline, the
/// directory's "where you are"), and gliding to a heading (a tile, the directory) or back to the top (the page's tab).
///
/// Every Shop page is laid out whole (no lazy stack), so every heading's place is known: the page reports each
/// heading's top in its own coordinates (`setAnchor`), and the scroll view reports its offset (`update`).
@MainActor @Observable final class PageScroll {
    /// The header's state. Changes only when it changes, so the header redraws only then.
    private(set) var mode: HeaderMode = .rest
    /// The section whose heading has reached the top ("Clothing", "The Latest"); the first one above them all.
    private(set) var section = ""
    /// The type heading within it that has reached the top ("Knitwear"), or "".
    private(set) var type = ""
    /// Which way the place line's words roll: going down the page the new word comes up from below.
    private(set) var rollFrom: Edge = .bottom
    /// Scrolled at all (pages without the tab row show their flat band until then).
    private(set) var scrolled = false
    /// The scroll view's position (its binding).
    var position = ScrollPosition(edge: .top)

    /// How far down the tabs start to make way: 140pt on a page with a tile row (once it has scrolled under the top
    /// row), 160pt elsewhere (SPEC §3).
    @ObservationIgnored var threshold: CGFloat = 160
    /// The page's headings in order: each section and its type headings.
    @ObservationIgnored var outline: [(section: String, types: [String])] = [] {
        didSet { recompute() }
    }
    /// Where the page should open: a section (and a type in it), once its heading has been laid out.
    @ObservationIgnored var landing: (section: String, type: String?)?

    @ObservationIgnored private var anchors: [String: CGFloat] = [:]
    @ObservationIgnored private var y: CGFloat = 0
    @ObservationIgnored private var maxY: CGFloat = 0
    @ObservationIgnored private var visibleHeight: CGFloat = 700
    @ObservationIgnored private var turnAt: CGFloat = 0
    @ObservationIgnored private var headingDown = true
    @ObservationIgnored private var glideUntil = Date.distantPast
    @ObservationIgnored private var forcedMode: HeaderMode?

    /// A heading has "reached the top" once it's within 12pt of the top row's foot (the prototype's 110px, 98px being
    /// where the top row ends). The page's coordinates start at the top row's foot, so a heading at `top` lands right
    /// under the top row when the page has scrolled `top`.
    static let reachSlack: CGFloat = 12

    init(threshold: CGFloat = 160, landing: (section: String, type: String?)? = nil) {
        self.threshold = threshold
        self.landing = landing
    }

    static func sectionKey(_ section: String) -> String { "s|" + section }
    static func typeKey(_ section: String, _ type: String) -> String { "t|" + section + "|" + type }

    // MARK: What the page reports

    /// A heading's top in the page's own coordinates (0 is the top of the page, right under the header).
    func setAnchor(_ key: String, _ top: CGFloat) {
        guard anchors[key] != top else { return }
        anchors[key] = top
        if let landing, key == Self.sectionKey(landing.section) || key == landing.type.map({ Self.typeKey(landing.section, $0) }) {
            land()
        }
        recompute()
    }

    /// The scroll view's offset (0 at rest, growing as the page goes up), how far it can go and how tall it is.
    func update(y newY: CGFloat, maxY: CGFloat, visibleHeight: CGFloat) {
        self.maxY = maxY
        self.visibleHeight = visibleHeight
        if headingDown {
            if newY > turnAt { turnAt = newY } else if newY < turnAt - 8 { headingDown = false; turnAt = newY }
        } else {
            if newY < turnAt { turnAt = newY } else if newY > turnAt + 8 { headingDown = true; turnAt = newY }
        }
        rollFrom = newY >= y ? .bottom : .top
        y = newY
        recompute()
    }

    private func recompute() {
        var next: HeaderMode = y < threshold ? .rest : (headingDown ? .down : .up)
        // The header holds still while the page glides to a section.
        if Date.now < glideUntil && y >= 140 { next = .down }
        if let forcedMode { next = forcedMode }
        if mode != next { mode = next }
        let isScrolled = y > 6
        if scrolled != isScrolled { scrolled = isScrolled }

        var sec = outline.first?.section ?? ""
        var typ = ""
        let atBottom = maxY > 0 && y >= maxY - 1
        for (s, types) in outline {
            guard let top = anchors[Self.sectionKey(s)], reached(top) || (atBottom && s == outline.last?.section) else { continue }
            sec = s
        }
        if let types = outline.first(where: { $0.section == sec })?.types {
            for t in types {
                if let top = anchors[Self.typeKey(sec, t)], reached(top) { typ = t }
            }
        }
        if section != sec { section = sec }
        if type != typ { type = typ }
    }

    private func reached(_ top: CGFloat) -> Bool { top <= y + Self.reachSlack }

    // MARK: Moving

    /// Glides the page so a heading lands just under the top row, with the tabs away (SPEC §3: the tile row is the
    /// page's table of contents). Long trips skip most of the way at once and glide the last ~0.6 of a screen, so it
    /// reads as arriving rather than a blur. Reduce Motion: it goes there at once.
    func glide(toSection section: String, type: String? = nil, reduceMotion: Bool) {
        let key = type.map { Self.typeKey(section, $0) } ?? Self.sectionKey(section)
        guard let top = anchors[key] ?? anchors[Self.sectionKey(section)] else { return }
        glide(toY: top, reduceMotion: reduceMotion)
    }

    /// Glides back to the top (the page's own tab, "All of Women" in the directory).
    func glideToTop(reduceMotion: Bool) {
        glide(toY: 0, reduceMotion: reduceMotion)
    }

    private func glide(toY target: CGFloat, reduceMotion: Bool) {
        let target = max(0, maxY > 0 ? min(target, maxY) : target)
        let distance = target - y
        guard abs(distance) > 0.5 else { return }
        glideUntil = .now.addingTimeInterval(reduceMotion ? 0.3 : 1.1)
        headingDown = true
        turnAt = target
        if reduceMotion {
            position.scrollTo(y: target)
            return
        }
        let stretch = 0.6 * visibleHeight
        Task { @MainActor in
            if abs(distance) > stretch {
                var jump = Transaction()
                jump.disablesAnimations = true
                withTransaction(jump) { position.scrollTo(y: target - (distance > 0 ? stretch : -stretch)) }
                try? await Task.sleep(for: .milliseconds(16))
            }
            withAnimation(Motion.glide(0.62)) { position.scrollTo(y: target) }
        }
    }

    /// Opens the page at its landing (a link to a category: the directory, a home room's title), at once, once the
    /// heading has been laid out.
    private func land() {
        guard let landing else { return }
        let key = landing.type.map { Self.typeKey(landing.section, $0) } ?? Self.sectionKey(landing.section)
        guard let top = anchors[key] else { return }
        self.landing = nil
        headingDown = true
        turnAt = top
        glideUntil = .now.addingTimeInterval(0.6)
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(16))
            var now = Transaction()
            now.disablesAnimations = true
            withTransaction(now) { position.scrollTo(y: top) }
        }
    }

    #if DEBUG
    /// For side-by-side screenshots with the prototype's still moments (Debug builds only): `-SOSPreviewAt Clothing
    /// -SOSPreviewScroll 560` opens the page 560pt past where Clothing's heading lands (`-SOSPreviewAt Handbags/Totes`,
    /// a type's heading; without `-SOSPreviewAt`, that far down), and `-SOSPreviewMode up` holds the header as if scrolling back up.
    func applyPreviewLaunchOptions() async {
        let defaults = UserDefaults.standard
        let extra = defaults.double(forKey: "SOSPreviewScroll")
        let at = defaults.string(forKey: "SOSPreviewAt")
        guard extra > 0 || at != nil else { return }
        try? await Task.sleep(for: .milliseconds(700))
        // "Handbags" is a section's heading; "Handbags/Totes" a type's within it.
        let key = at.map { $0.contains("/") ? Self.typeKey(String($0.split(separator: "/")[0]), String($0.split(separator: "/")[1])) : Self.sectionKey($0) }
        let base = key.flatMap { anchors[$0] } ?? 0
        let target = base + extra
        turnAt = target
        headingDown = true
        position.scrollTo(y: target)
        switch defaults.string(forKey: "SOSPreviewMode") {
        case "up": forcedMode = .up
        case "down": forcedMode = .down
        default: break
        }
        try? await Task.sleep(for: .milliseconds(100))
        recompute()
    }
    #endif
}

/// A page's scroll view: the page laid out whole in its own coordinates, reporting its offset and its headings to its
/// `PageScroll`.
struct PageScrollView<Content: View>: View {
    let scroll: PageScroll
    /// Pull to refresh fetches the closet again (APP-SPEC §3.1).
    var refresh: (@MainActor @Sendable () async -> Void)? = nil
    var scrollDisabled = false
    /// The tab row's room at the top of the page (it hangs over the page, under the top row): empty, so the page starts
    /// under the tabs at rest and nothing moves when they go.
    var topRoom: CGFloat = 0
    @ViewBuilder var content: () -> Content

    var body: some View {
        @Bindable var scroll = scroll
        ScrollView {
            content()
                .padding(.top, topRoom)
                .coordinateSpace(.named(PageSpace.name))
        }
        .scrollIndicators(.hidden)
        .scrollPosition($scroll.position)
        .scrollDisabled(scrollDisabled)
        .refreshable(enabled: refresh != nil) { await refresh?() }
        .onScrollGeometryChange(for: ScrollFacts.self) { g in
            ScrollFacts(
                y: g.contentOffset.y + g.contentInsets.top,
                maxY: max(0, g.contentSize.height + g.contentInsets.top + g.contentInsets.bottom - g.containerSize.height),
                height: g.containerSize.height - g.contentInsets.top - g.contentInsets.bottom)
        } action: { _, facts in
            scroll.update(y: facts.y, maxY: facts.maxY, visibleHeight: facts.height)
        }
        #if DEBUG
        .task { await scroll.applyPreviewLaunchOptions() }
        #endif
    }

    private struct ScrollFacts: Equatable {
        var y: CGFloat
        var maxY: CGFloat
        var height: CGFloat
    }
}

/// The page's own coordinates: 0 is the top of the page, right under the top row (the tab row's room comes first).
nonisolated enum PageSpace {
    static let name = "page"
}

extension View {
    /// Reports this heading's top, in the page's coordinates, to the page's scroll.
    func pageAnchor(_ key: String, in scroll: PageScroll) -> some View {
        onGeometryChange(for: CGFloat.self) { $0.frame(in: .named(PageSpace.name)).minY } action: { top in
            scroll.setAnchor(key, top)
        }
    }

    /// Pull to refresh only where the page has something to refresh.
    @ViewBuilder func refreshable(enabled: Bool, action: @escaping @Sendable () async -> Void) -> some View {
        if enabled { refreshable(action: action) } else { self }
    }
}
