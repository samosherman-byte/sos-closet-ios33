import SwiftUI
import UIKit

/// A bag on the turntable, as Home gives it: its cut-out (copied unchanged from the site's `public/home/`), its true
/// size and where it stands in its frame, its credit, and what tapping it in front does.
struct TableBag: Identifiable {
    let id: String
    let image: UIImage?
    /// How wide the bag is (cm), for true sizes to each other.
    let cm: Double
    /// Where the bag starts and ends in its 4:5 frame (shares of the height), so every bag stands on the same floor.
    let top: Double
    let bot: Double
    /// The credit under the table: the designer, then the bag's name · its price (or "New arrival").
    let designer: String
    let name: String
    let sub: String
    /// What VoiceOver says for it ("Gucci Jackie 1961, $2,600").
    let label: String
    let open: () -> Void
}

/// Everything that moves on the turntable (the site's `Table` class in `app/lib/home/turntable.ts`): which bag is in
/// front, the turns and their timing, a swipe and where it lets go, and the first-time turn into place.
@MainActor @Observable
final class TurntableModel {
    /// Where the table stood when you left Home, this launch (nil: not turned yet, so the intro plays).
    private static var kept: Double?

    let count: Int
    /// Which bag is in front (fractional while it turns).
    private(set) var pos: Double
    /// Where a turn is heading (nil at rest).
    private(set) var to: Double?
    /// The bags have faded up.
    private(set) var ready: Bool
    /// The way the front bag last changed (+1: the next one came round), for the credit's slide.
    private(set) var creditDirection = 1
    private(set) var front: Int

    @ObservationIgnored private var ticker: FrameTicker?
    @ObservationIgnored private var turn: (from: Double, to: Double, start: CFTimeInterval, duration: Double, ease: (Double) -> Double)?
    @ObservationIgnored private var drag: (anchor: Double, pos: Double)?
    @ObservationIgnored private var intro = false

    init(count: Int, front: Int) {
        self.count = count
        let p = Self.kept ?? Double(front)
        pos = p
        self.front = TurntableMath.frontAt(p, count)
        ready = Self.kept != nil
    }

    /// The first time Home opens this launch, the table turns one bag into place (the Bréa round to the Jackie, 2s
    /// ease-out after 150ms) as the bags fade up over 1s, so it's plain that it turns. Coming back, it stands as you
    /// left it. Reduce Motion: no intro turn.
    func appear(front start: Int, reduceMotion: Bool) {
        guard Self.kept == nil, !ready else { return }
        if reduceMotion {
            ready = true
            setPos(Double(start))
            Self.kept = pos
            return
        }
        intro = true
        setPos(Double(start - 1))
        withAnimation(Motion.ease(1)) { ready = true }
        go(Double(start), duration: 2, delay: 0.15, ease: TurntableMath.out, reduceMotion: false)
    }

    var atRest: Bool { to == nil && drag == nil && abs(pos - TurntableMath.round(pos)) < 0.02 }

    /// Turn by a number of bags (the arrows).
    func turn(by bags: Int, reduceMotion: Bool) {
        let base = to ?? TurntableMath.round(pos)
        go(base + Double(bags), reduceMotion: reduceMotion)
    }

    /// Bring bag `i` round to the front, the short way.
    func turnTo(_ i: Int, reduceMotion: Bool) {
        let current = to ?? TurntableMath.round(pos)
        let k = ((i - Int(current)) % count + count) % count
        guard k != 0 else { return }
        go(current + Double(Double(k) <= Double(count) / 2 ? k : k - count), reduceMotion: reduceMotion)
    }

    // MARK: A swipe

    /// Taking hold: the table stops where it is (even mid-turn) and follows the finger from there. The swipe counts
    /// from the bag it rests on, or the one it's heading to, so quick swipes in a row turn a bag each.
    func dragBegan() {
        ticker?.stop()
        let anchor = to.map { abs($0 - pos) <= 1 ? $0 : TurntableMath.round(pos) } ?? TurntableMath.round(pos)
        to = nil
        turn = nil
        intro = false
        drag = (anchor, pos)
    }

    /// One bag's travel (front to side, `rx × W × 0.866`) turns the table one bag, up to a bag either way.
    func dragChanged(dx: Double, travel: Double) {
        guard let d = drag, travel > 0 else { return }
        let free = d.pos - dx / travel - d.anchor
        setPos(d.anchor + TurntableMath.resist(free))
    }

    /// Letting go: on to the next bag the way it was swiped, or back to the one it started on. `v` is the finger's
    /// speed in pt/ms, + for a swipe to the left (which turns the table on).
    func dragEnded(v: Double, reduceMotion: Bool) {
        guard let d = drag else { return }
        drag = nil
        let target = TurntableMath.letGo(anchor: d.anchor, pos: pos, v: v)
        go(target, duration: TurntableMath.settleDuration(bags: target - pos), ease: TurntableMath.out, reduceMotion: reduceMotion)
    }

    // MARK: Turning

    private func go(_ target: Double, duration: Double? = nil, delay: Double = 0, ease: @escaping (Double) -> Double = TurntableMath.inOut, reduceMotion: Bool) {
        ticker?.stop()
        to = target
        if reduceMotion || abs(target - pos) < 0.001 {
            setPos(target)
            done()
            return
        }
        turn = (pos, target, CACurrentMediaTime() + delay, duration ?? TurntableMath.turnDuration(bags: target - pos), ease)
        let ticker = ticker ?? FrameTicker { [weak self] now in self?.step(now) }
        self.ticker = ticker
        ticker.start()
    }

    private func step(_ now: CFTimeInterval) {
        guard let t = turn else { ticker?.stop(); return }
        let p = max(0, min(1, (now - t.start) / t.duration))
        setPos(t.from + (t.to - t.from) * t.ease(p))
        if p >= 1 { done() }
    }

    private func done() {
        ticker?.stop()
        turn = nil
        to = nil
        intro = false
        setPos(TurntableMath.round(pos))
        Self.kept = pos
    }

    private func setPos(_ p: Double) {
        pos = p
        let f = TurntableMath.frontAt(p, count)
        if f != front {
            creditDirection = ((f - front) % count + count) % count == 1 ? 1 : -1
            front = f
        }
    }
}

/// Calls back once a frame while a turn runs (a display link, so the table moves with the screen's refresh).
private final class FrameTicker: NSObject {
    private var link: CADisplayLink?
    private let tick: (CFTimeInterval) -> Void

    init(_ tick: @escaping (CFTimeInterval) -> Void) {
        self.tick = tick
    }

    func start() {
        guard link == nil else { return }
        let link = CADisplayLink(target: self, selector: #selector(step(_:)))
        link.add(to: .main, forMode: .common)
        self.link = link
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func step(_ link: CADisplayLink) {
        tick(link.targetTimestamp)
    }
}

/// The turntable of three bags (APP-SPEC §3.4; the site's `Turntable.tsx`): cut from their own photos at their true
/// sizes, on one round table seen from a little above. Swipe it (a bag a swipe), tap a side bag to bring it round, or
/// use the arrows; the bag in front, and its credit, open its piece. The bags stay inside the page's stacking, so
/// scrolling they pass under the header like every other piece.
struct TurntableView: View {
    let bags: [TableBag]
    /// The bag in front to begin with (the Jackie).
    let front: Int
    let width: CGFloat
    let model: TurntableModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var maps: [String: [UInt8]] = [:]

    /// Phones: the stage runs to the screen's edges at 1.3 : 1 (SPEC §11a).
    private var height: CGFloat { (width / 1.3).rounded(.down) }
    private var shape: TurntableMath.Shape { .forStage(width: width) }

    var body: some View {
        VStack(spacing: 6) {
            stage
            credits
        }
    }

    // MARK: The stage

    private var stage: some View {
        let w = Double(width), h = Double(height)
        return ZStack(alignment: .topLeading) {
            ForEach(Array(bags.enumerated()), id: \.element.id) { i, bag in
                let s = TurntableMath.spot(i, of: bags.count, pos: model.pos, w: w, h: h, shape: shape, cm: bag.cm, bot: bag.bot)
                BagCutout(image: bag.image, wash: s.wash)
                    .frame(width: s.fw, height: s.fh)
                    .scaleEffect(s.sc, anchor: UnitPoint(x: 0.5, y: bag.bot))
                    .position(x: s.tx + s.fw / 2, y: s.ty + s.fh / 2)
                    .zIndex(500 + s.c * 400)
                    .opacity(model.ready ? 1 : 0)
            }
        }
        .frame(width: width, height: height, alignment: .topLeading)
        .contentShape(.rect)
        .onTapGesture(coordinateSpace: .local) { point in tap(at: point) }
        .gesture(SidewaysPan(
            began: { model.dragBegan() },
            changed: { dx in model.dragChanged(dx: dx, travel: shape.rx * w * 0.866) },
            ended: { vx in model.dragEnded(v: -vx / 1000, reduceMotion: reduceMotion) }
        ))
        .task { readMaps() }
        .onAppear { model.appear(front: front, reduceMotion: reduceMotion) }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Three bags on a turntable")
        .accessibilityValue(bags.indices.contains(model.front) ? bags[model.front].label : "")
        .accessibilityHint("Swipe up or down to turn it. Double-tap to open the bag in front.")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: model.turn(by: 1, reduceMotion: true)
            case .decrement: model.turn(by: -1, reduceMotion: true)
            @unknown default: break
            }
        }
        .accessibilityAction { openFront() }
    }

    /// A tap: the bag in front opens its piece; a bag at the side comes round to the front. The bags are found by their
    /// own outline, so a tap on the white between them does nothing.
    private func tap(at point: CGPoint) {
        let i = hit(point)
        guard i >= 0 else { return }
        if i == model.front && model.atRest { bags[i].open() } else { model.turnTo(i, reduceMotion: reduceMotion) }
    }

    private func openFront() {
        if bags.indices.contains(model.front) { bags[model.front].open() }
    }

    /// The bag under a point on the stage (nearest first), by its cut-out's alpha sampled 60 × 75; −1 on the white.
    private func hit(_ point: CGPoint) -> Int {
        let w = Double(width), h = Double(height)
        let spots = bags.enumerated().map { i, bag in
            TurntableMath.spot(i, of: bags.count, pos: model.pos, w: w, h: h, shape: shape, cm: bag.cm, bot: bag.bot)
        }
        for i in bags.indices.sorted(by: { spots[$0].c > spots[$1].c }) {
            let m = spots[i]
            let fu = ((point.x - m.tx - m.fw / 2) / m.sc + m.fw / 2) / m.fw
            let fv = ((point.y - m.ty - m.oy) / m.sc + m.oy) / m.fh
            guard fu >= 0, fu < 1, fv >= 0, fv < 1 else { continue }
            if let map = maps[bags[i].id] {
                if map[Int(fv * 75) * 60 + Int(fu * 60)] > 60 { return i }
            } else if fu > 0.05, fu < 0.95, fv > bags[i].top, fv < bags[i].bot {
                return i
            }
        }
        return -1
    }

    private func readMaps() {
        for bag in bags where maps[bag.id] == nil {
            if let image = bag.image, let map = Self.alphaMap(image) { maps[bag.id] = map }
        }
    }

    /// A cut-out's alpha, sampled 60 × 75 (the site's `MAP_W` × `MAP_H`), top row first.
    nonisolated static func alphaMap(_ image: UIImage) -> [UInt8]? {
        guard let cg = image.cgImage else { return nil }
        let w = 60, h = 75
        var data = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = data.withUnsafeMutableBytes { raw in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        return drawn ? (0..<(w * h)).map { data[$0 * 4 + 3] } : nil
    }

    // MARK: The credit

    /// The front bag's credit between two round arrows (44pt, 20pt chevrons, a 1.4 stroke), the arrows 8pt from its
    /// words (as wide as they are, up to 220pt, as in the app prototype). The old credit slides out
    /// the way the table turns (14pt, .35s) as the new one comes in from the other side.
    private var credits: some View {
        let d = CGFloat(model.creditDirection)
        return HStack(spacing: 8) {
            arrow(back: true) { model.turn(by: -1, reduceMotion: reduceMotion) }
                .accessibilityLabel("Turn to the bag on the left")
            ZStack {
                if bags.indices.contains(model.front) {
                    credit(bags[model.front])
                        .id(model.front)
                        .transition(reduceMotion ? .opacity : .asymmetric(
                            insertion: .offset(x: 14 * d).combined(with: .opacity),
                            removal: .offset(x: -14 * d).combined(with: .opacity)
                        ))
                }
            }
            .animation(.easeOut(duration: 0.35), value: model.front)
            arrow(back: false) { model.turn(by: 1, reduceMotion: reduceMotion) }
                .accessibilityLabel("Turn to the bag on the right")
        }
        .opacity(model.ready ? 1 : 0)
        .animation(Motion.ease(1).delay(0.5), value: model.ready)
    }

    private func credit(_ bag: TableBag) -> some View {
        Button(action: bag.open) {
            VStack(spacing: 5) {
                Text(bag.designer)
                    .textStyle(.creditDesigner)
                    .foregroundStyle(.ink)
                Text("\(Text(bag.name).foregroundStyle(.ink2)) · \(bag.sub)")
                    .textStyle(.creditLine)
                    .foregroundStyle(.muted)
                    .monospacedDigit()
            }
            .lineLimit(1)
            .fixedSize()
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        // (Between the two arrows on one line: it grows only so far.)
        .dynamicTypeSize(...DynamicTypeSize.xxLarge)
        .accessibilityLabel(bag.label)
    }

    private func arrow(back: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Chevron(back: back)
                .stroke(.ink, style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
                .frame(width: 20, height: 20)
                .frame(width: 44, height: 44)
                .contentShape(.circle)
        }
        .buttonStyle(.plain)
    }
}

/// A bag's cut-out with its soft all-round shadow (`drop-shadow(0 0 14px` ink at 8%`)`, none under it), and over it a
/// white copy of its own outline faded in by the wash, so only scale, place and opacity change while the table turns.
private struct BagCutout: View {
    let image: UIImage?
    let wash: Double

    var body: some View {
        if let image {
            ZStack {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .shadow(color: .ink.opacity(0.08), radius: 7)
                Image(uiImage: image)
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundStyle(.white)
                    .opacity(wash)
            }
            .accessibilityHidden(true)
        }
    }
}

/// The site's chevrons in a 24-unit box: `M14.5 5.5L8 12l6.5 6.5` (back) and `M9.5 5.5L16 12l-6.5 6.5`.
nonisolated struct Chevron: Shape {
    var back = false

    func path(in rect: CGRect) -> Path {
        let k = rect.width / 24
        var p = Path()
        if back {
            p.move(to: CGPoint(x: 14.5 * k, y: 5.5 * k)); p.addLine(to: CGPoint(x: 8 * k, y: 12 * k)); p.addLine(to: CGPoint(x: 14.5 * k, y: 18.5 * k))
        } else {
            p.move(to: CGPoint(x: 9.5 * k, y: 5.5 * k)); p.addLine(to: CGPoint(x: 16 * k, y: 12 * k)); p.addLine(to: CGPoint(x: 9.5 * k, y: 18.5 * k))
        }
        return p
    }
}

/// A sideways drag that leaves vertical scrolling to the page (the site's `touch-action: pan-y`): it only takes hold
/// when the finger moves more sideways than up or down.
private struct SidewaysPan: UIGestureRecognizerRepresentable {
    var began: () -> Void
    var changed: (Double) -> Void
    var ended: (Double) -> Void

    func makeCoordinator(converter: CoordinateSpaceConverter) -> Coordinator { Coordinator() }

    func makeUIGestureRecognizer(context: Context) -> UIPanGestureRecognizer {
        let pan = UIPanGestureRecognizer()
        pan.delegate = context.coordinator
        return pan
    }

    func handleUIGestureRecognizerAction(_ pan: UIPanGestureRecognizer, context: Context) {
        switch pan.state {
        case .began: began()
        case .changed: changed(pan.translation(in: pan.view).x)
        case .ended: ended(pan.velocity(in: pan.view).x)
        case .cancelled, .failed: ended(0)
        default: break
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        func gestureRecognizerShouldBegin(_ g: UIGestureRecognizer) -> Bool {
            guard let pan = g as? UIPanGestureRecognizer else { return true }
            let v = pan.velocity(in: pan.view)
            return abs(v.x) > abs(v.y)
        }
    }
}
