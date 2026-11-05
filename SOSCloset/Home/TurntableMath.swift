import CoreGraphics

/// The turntable's geometry and the rules of a swipe, ported unchanged from the site's `app/lib/home/turntable.ts`
/// (`spot`, `frontAt`, `resist`, `letGo` and its constants; SPEC §11a). Pure, so the tests check it against the site's.
nonisolated enum TurntableMath {
    /// The table's shape, as shares of the stage's width (fw, rx) and height (floor, lift); shrink and wash at the back.
    struct Shape: Hashable, Sendable {
        /// A 34 cm bag's frame width, in front.
        var fw: Double
        /// How far the side bags stand from the middle.
        var rx: Double
        /// Where the bag in front stands.
        var floor: Double
        /// How much higher the very back stands.
        var lift: Double
        /// How much smaller a bag is at the very back.
        var shrink: Double
        /// How far toward the white it's washed at the very back.
        var wash: Double

        /// The site's `TURNTABLE.narrow`: a stage under 560pt wide (phones).
        static let narrow = Shape(fw: 0.56, rx: 0.36, floor: 0.965, lift: 0.12, shrink: 0.44, wash: 0.2)
        /// The site's `TURNTABLE.wide`.
        static let wide = Shape(fw: 0.5, rx: 0.395, floor: 0.965, lift: 0.13, shrink: 0.42, wash: 0.2)

        static func forStage(width: Double) -> Shape { width < 560 ? .narrow : .wide }
    }

    /// A bag's place on the stage for a turn of the table.
    struct Spot: Hashable, Sendable {
        /// The frame's left and top on the stage (pt), and its scale about the bag's foot.
        var tx: Double
        var ty: Double
        var sc: Double
        /// cos θ: 1 in front, −1 at the very back.
        var c: Double
        /// How far toward the white it's washed.
        var wash: Double
        /// The frame's width and height at scale 1, and the foot's height in it (pt).
        var fw: Double
        var fh: Double
        var oy: Double
    }

    /// A swipe turns at most one bag: past one either way, the extra travel counts at 20% and stops at 0.12 of a bag.
    static let give = 0.2
    static let stop = 0.12
    /// Letting go, it goes on to the next bag if the drag covered a quarter of one, or was a quick flick (pt/ms).
    static let past = 0.25
    static let flick = 0.35

    /// Bag `i` of `n` at turn `pos` (which bag is in front; whole numbers at rest) on a stage `w` × `h`: it sits at
    /// θ = (i − pos) × 360°/n; with t = (1 − cos θ)/2 (0 in front, 1 at the very back) it stands sin θ × rx × W from
    /// the middle, at H × (floor − lift × t), scaled (cm / 34) × (1 − shrink × t) about its foot, washed by
    /// wash × t^1.25.
    static func spot(_ i: Int, of n: Int, pos: Double, w: Double, h: Double, shape g: Shape, cm: Double, bot: Double) -> Spot {
        var a = (Double(i) - pos) * 2 * .pi / Double(n)
        a = atan2(sin(a), cos(a))
        let c = cos(a)
        let t = (1 - c) / 2
        let fw = g.fw * w
        let fh = fw * 1.25
        return Spot(
            tx: w / 2 + sin(a) * g.rx * w - fw / 2,
            ty: h * (g.floor - g.lift * t) - bot * fh,
            sc: (cm / 34) * (1 - g.shrink * t),
            c: c,
            wash: g.wash * pow(t, 1.25),
            fw: fw,
            fh: fh,
            oy: bot * fh
        )
    }

    /// The bag that's in front at turn `pos`.
    static func frontAt(_ pos: Double, _ n: Int) -> Int {
        let r = Int(round(pos))
        return ((r % n) + n) % n
    }

    /// JavaScript's `Math.round`, which the site uses: halves go up (−1.5 → −1), not away from zero.
    static func round(_ x: Double) -> Double { (x + 0.5).rounded(.down) }

    /// How far the table turns from the bag a swipe started on (in bags) for `d` bags of the finger's travel: one for
    /// one up to a bag either way; past that the extra counts at 20% and stops at 0.12 of a bag.
    static func resist(_ d: Double) -> Double {
        let a = abs(d)
        return a <= 1 ? d : (d < 0 ? -1 : 1) * (1 + min(stop, (a - 1) * give))
    }

    /// Where the table settles when a swipe lets go: `anchor` is the bag it started on, `pos` where the table is now,
    /// `v` the finger's speed (pt/ms, + the way that turns the table on, a swipe to the left). A quick flick turns it
    /// one bag the way it's flicked; otherwise on to the next bag if the drag covered a quarter of one, else back.
    static func letGo(anchor: Double, pos: Double, v: Double) -> Double {
        if abs(v) >= flick { return anchor + (v < 0 ? -1 : 1) }
        let d = pos - anchor
        return abs(d) >= past ? anchor + (d < 0 ? -1 : 1) : anchor
    }

    /// A turn eases in and out over 700ms plus 300ms per bag, at most 1.5s.
    static func turnDuration(bags: Double) -> Double { min(1.5, 0.7 + 0.3 * abs(bags)) }
    /// Letting go of a drag eases out over 520ms plus 320ms per bag still to go.
    static func settleDuration(bags: Double) -> Double { 0.52 + 0.32 * abs(bags) }

    static func inOut(_ p: Double) -> Double { p < 0.5 ? 4 * p * p * p : 1 - pow(-2 * p + 2, 3) / 2 }
    static func out(_ p: Double) -> Double { 1 - pow(1 - p, 3) }
}
