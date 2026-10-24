import XCTest

/// TEMPORARY, for branch nav/directions: drives each navigation direction with real swipes and taps, as a finger
/// would, so the Simulator's screen can be recorded and checked (the tabs making way, the glass, the tab bar
/// shrinking, swiping and tapping between departments). Runs only when asked: `TEST_RUNNER_SOS_TOUR=A` or `B`.
final class DirectionsTour: XCTestCase {
    private var direction: String? { ProcessInfo.processInfo.environment["SOS_TOUR"] }

    @MainActor
    func testTour() throws {
        guard let direction, !direction.isEmpty else { throw XCTSkip("A tour runs only when asked: TEST_RUNNER_SOS_TOUR=A or B") }
        let app = XCUIApplication()
        app.launchArguments = ["-SOSDirection", direction, "-SOSPage", "women"]
        app.launch()
        pause(2)

        // Down through the handbags: the tabs make way (A) or the tab bar shrinks (B).
        app.swipeUp(velocity: .slow)
        pause(1.2)
        app.swipeUp(velocity: .slow)
        pause(1.5)
        snapshot("1 scrolled down")
        // A little back up: the classic header comes back (A), the tab bar grows again (B).
        app.swipeDown(velocity: .slow)
        pause(1.5)
        snapshot("2 back up a little")

        // Sideways to the next department, under the finger, then back by its tab.
        app.swipeLeft()
        pause(1.5)
        snapshot("3 swiped to Men")
        app.buttons["Women"].firstMatch.tap()
        pause(1.5)
        // A long trip along the map, by a tab.
        app.buttons["Art & Home"].firstMatch.tap()
        pause(1.8)
        snapshot("4 tapped Art & Home")
        app.buttons["Shop All"].firstMatch.tap()
        pause(1.8)

        if direction == "A" {
            app.buttons["SOS Closet home"].tap() // the logo: Home slides in from the left
            pause(1.8)
            snapshot("5 home")
            app.buttons["Menu"].tap()
            pause(1.5)
            snapshot("6 menu")
        } else {
            app.tabBars.buttons["Saved"].tap()
            pause(1.2)
            app.tabBars.buttons["Bag"].tap()
            pause(1.2)
            snapshot("5 bag")
            app.tabBars.buttons["Home"].tap()
            pause(1.5)
            app.swipeUp(velocity: .slow)
            pause(1.5)
            snapshot("6 home scrolled")
            app.tabBars.buttons["Shop"].tap()
            pause(1.5)
        }
    }

    private func pause(_ seconds: TimeInterval) {
        Thread.sleep(forTimeInterval: seconds)
    }

    @MainActor
    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
