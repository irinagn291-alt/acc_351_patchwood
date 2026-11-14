import XCTest

final class TrailUITests: XCTestCase {
    func testEntireTrailAndRestoredCheckpoint() {
        let app = XCUIApplication()
        app.launchEnvironment["PATCHWOOD_TEST_JOURNAL"] = "patchwood.test." + UUID().uuidString
        app.launch()
        app.buttons["tab-Trail map"].tap()
        XCTAssertFalse(app.buttons["lesson-callsign"].isEnabled)
        app.buttons["route-2"].tap()
        XCTAssertFalse(app.buttons["lesson-weather"].isEnabled)
        app.buttons["tab-Basecamp"].tap()
        capture("Basecamp")
        let missions = Trailbook.missions
        XCTAssertEqual(missions.count, 100)
        XCTAssertEqual(Set(missions.map(\.id)).count, 100)
        XCTAssertEqual(Set(missions.map(\.title)).count, 100)
        XCTAssertEqual(missions.flatMap(\.challenges).count, 300)
        for (mission, level) in missions.enumerated() {
            let answers = level.challenges.map(\.answer)
            app.buttons["featuredMission"].tap()
            tapAction(app)
            for (step, answer) in answers.enumerated() {
                if mission == 0 && step == 0 {
                    XCTAssertFalse(app.buttons["missionAction"].isEnabled)
                    app.buttons["choice-0"].tap()
                    tapAction(app)
                    XCTAssertTrue(app.buttons["missionAction"].label.contains("Try again"))
                    tapAction(app)
                    app.buttons["choice-1"].tap()
                    app.terminate()
                    app.launch()
                    app.buttons["featuredMission"].tap()
                    XCTAssertTrue(app.buttons["choice-1"].isSelected)
                    capture("Challenge")
                } else {
                    if mission == 0 && step == 2 {
                        app.buttons["choice-0"].tap()
                        app.buttons["undo"].tap()
                        XCTAssertFalse(app.buttons["missionAction"].isEnabled)
                    }
                    for piece in answer { app.buttons["choice-\(piece)"].tap() }
                }
                tapAction(app)
                XCTAssertTrue(app.buttons["missionAction"].label.contains(step == 2 ? "Log mission" : "Continue"))
                tapAction(app)
            }
            XCTAssertTrue(app.staticTexts["Mission complete!"].waitForExistence(timeout: 3))
            if mission == 0 { XCTAssertTrue(app.staticTexts["2/3"].exists) }
            if mission == 2 { capture("Station-patch") }
            if mission == 99 {
                XCTAssertTrue(app.staticTexts["Aurora Operator"].exists)
                capture("Level-100")
            }
            tapAction(app)
        }
        app.buttons["tab-Field log"].tap()
        XCTAssertTrue(app.staticTexts["3000"].exists)
        capture("Field-log")
        app.buttons["tab-Basecamp"].tap()
        app.buttons["featuredMission"].tap()
        tapAction(app)
        for answer in missions[0].challenges.map(\.answer) {
            for piece in answer { app.buttons["choice-\(piece)"].tap() }
            tapAction(app)
            tapAction(app)
        }
        XCTAssertTrue(app.staticTexts["+0"].exists)
        tapAction(app)
        app.terminate()
        app.launch()
        app.buttons["tab-Field log"].tap()
        XCTAssertTrue(app.staticTexts["3000"].exists)
    }

    func testCourseMapAndFirstMission() {
        let app = XCUIApplication()
        app.launchEnvironment["PATCHWOOD_TEST_JOURNAL"] = "patchwood.test." + UUID().uuidString
        app.launch()
        app.buttons["tab-Trail map"].tap()
        XCTAssertTrue(app.staticTexts["0 of 100 levels complete · 16 forest stations"].exists)
        let finalRoute = app.buttons["route-16"]
        for _ in 0..<24 {
            if finalRoute.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(finalRoute.isHittable)
        finalRoute.tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["lesson-level-100"].exists)
        XCTAssertFalse(app.buttons["lesson-level-100"].isEnabled)
        capture("Final-route")
        app.buttons["tab-Basecamp"].tap()
        app.buttons["featuredMission"].tap()
        tapAction(app)
        for challenge in Trailbook.missions[0].challenges {
            for piece in challenge.answer { app.buttons["choice-\(piece)"].tap() }
            tapAction(app)
            tapAction(app)
        }
        tapAction(app)
        app.buttons["tab-Field log"].tap()
        XCTAssertTrue(app.staticTexts["30"].exists)
    }

    private func tapAction(_ app: XCUIApplication) {
        let action = app.buttons["missionAction"]
        XCTAssertTrue(action.isHittable)
        action.tap()
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
