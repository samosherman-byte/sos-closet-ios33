import Foundation
import Testing
@testable import SOSCloset

/// The turntable's geometry and swipes, the same cases as the site's app/lib/home/turntable.test.ts (SPEC §11a).
struct TurntableTests {
    let w = 666.0, h = 430.0
    let g = TurntableMath.Shape.wide
    // The Bréa, the Jackie and the Bamboo: (cm, bot).
    let brea = (33.0, 0.871), jackie = (34.0, 0.927), bamboo = (29.0, 0.9)

    func spot(_ i: Int, _ pos: Double, _ bag: (Double, Double)) -> TurntableMath.Spot {
        TurntableMath.spot(i, of: 3, pos: pos, w: w, h: h, shape: g, cm: bag.0, bot: bag.1)
    }

    func close(_ a: Double, _ b: Double) -> Bool { abs(a - b) < 0.005 }

    @Test func theBagInFrontStandsInTheMiddleWholeAtItsTrueSizeOnTheFloor() {
        let s = spot(1, 1, jackie)
        #expect(close(s.c, 1))
        #expect(close(s.tx + s.fw / 2, w / 2))
        #expect(close(s.sc, 1))
        #expect(close(s.wash, 0))
        #expect(close(s.fw, 0.5 * w))
        #expect(close(s.ty + s.oy, h * 0.965))
        #expect(close(spot(0, 0, brea).sc, 33.0 / 34))
    }

    @Test func theSideBagsStandFurtherBack() {
        let left = spot(0, 1, brea), right = spot(2, 1, bamboo), front = spot(1, 1, jackie)
        #expect(close(left.c, -0.5))
        #expect(left.tx + left.fw / 2 < w / 2)
        #expect(right.tx + right.fw / 2 > w / 2)
        #expect(close(left.sc, 33.0 / 34 * (1 - 0.42 * 0.75)))
        #expect(close(right.sc, 29.0 / 34 * (1 - 0.42 * 0.75)))
        #expect(close(left.ty + left.oy, h * (0.965 - 0.13 * 0.75)))
        #expect(close(left.wash, 0.2 * pow(0.75, 1.25)))
        #expect(front.c > left.c)
    }

    @Test func itTurnsTheShortWayRoundAndSaysWhichBagIsInFront() {
        #expect(TurntableMath.frontAt(1, 3) == 1)
        #expect(TurntableMath.frontAt(1.4, 3) == 1)
        #expect(TurntableMath.frontAt(1.6, 3) == 2)
        #expect(TurntableMath.frontAt(-1, 3) == 2)
        #expect(TurntableMath.frontAt(3, 3) == 0)
        let a = spot(0, 0.3, brea), b = spot(0, 3.3, brea)
        #expect(close(b.tx, a.tx) && close(b.sc, a.sc))
    }

    @Test func aSwipeFollowsTheFingerUpToABagThenGivesAndStops() {
        let r = TurntableMath.resist
        #expect(r(0) == 0)
        #expect(close(r(0.4), 0.4) && close(r(-0.9), -0.9) && close(r(1), 1))
        #expect(close(r(1.25), 1.05) && close(r(-1.5), -1.1))
        #expect(close(r(1.6), 1.12) && close(r(3), 1.12) && close(r(-9), -1.12))
        #expect(TurntableMath.frontAt(4 + r(3), 3) == TurntableMath.frontAt(5, 3))
    }

    @Test func lettingGoTurnsOneBagOrSpringsBack() {
        let l = TurntableMath.letGo
        #expect(l(4, 4.25, 0) == 5 && l(4, 4.6, 0.1) == 5 && l(4, 3.7, -0.1) == 3)
        #expect(l(4, 5.12, 0) == 5 && l(4, 5.12, 3) == 5 && l(4, 2.88, -3) == 3)
        // A short, slow nudge springs back.
        #expect(l(4, 4.15, 0.1) == 4 && l(4, 3.8, -0.2) == 4 && l(4, 4, 0) == 4 && l(4, 4.3, -0.2) == 5)
        // A quick flick turns one bag its way, however short.
        #expect(l(4, 4.08, 0.35) == 5 && l(4, 3.95, -0.6) == 3 && l(4, 4, 1.5) == 5 && l(4, 4.6, -0.8) == 3)
        #expect(l(4, 4.08, 0.34) == 4)
        // Quick swipes in a row each turn a bag.
        #expect(l(5, 4.6 + 0.5, 0.9) == 6 && l(5, 4.45 + 0.3, 0.9) == 6)
        #expect(l(5, 4.6 + 0.7, 0.2) == 6 && l(5, 4.6 + 0.5, 0.2) == 5)
    }
}
