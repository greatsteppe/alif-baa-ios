//
//  GoldenPathUITests.swift
//  alif-baa-iosUITests
//
//  End-to-end walk of the reference build (§3.2): reading level "A beginner" +
//  program "Fast", through the complete Lesson 1 to the MashaAllah summary.
//

import XCTest

final class GoldenPathUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testBeginnerFastGoldenPath() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-uitest"]
        app.launch()

        // Onboarding 1 — reading level
        let beginner = app.staticTexts["A beginner"].firstMatch
        XCTAssertTrue(beginner.waitForExistence(timeout: 5))
        snap(app, "01-onboarding-level")
        beginner.tap()
        app.buttons["Proceed"].tap()

        // Onboarding 2 — program
        let fast = app.staticTexts["Fast"].firstMatch
        XCTAssertTrue(fast.waitForExistence(timeout: 3))
        snap(app, "02-onboarding-program")
        fast.tap()
        app.buttons["Proceed"].tap()

        // Configuring (~1.6 s) → Alphabet tab
        let lesson1 = app.staticTexts["Alif Ba Ta Tha"].firstMatch
        XCTAssertTrue(lesson1.waitForExistence(timeout: 10))
        snap(app, "03-alphabet")
        lesson1.tap()

        // Lesson intro
        let start = app.buttons["Start"]
        XCTAssertTrue(start.waitForExistence(timeout: 3))
        snap(app, "04-lesson-intro")
        start.tap()

        // 4 letters × (draw, select-sound, articulation)
        let check = app.buttons["Check"]
        let proceed = app.buttons["Proceed"]
        for step in 0..<12 {
            XCTAssertTrue(check.waitForExistence(timeout: 5), "Check button missing at step \(step)")

            if app.staticTexts["Draw the letter along the outline, then tap Proceed"].exists {
                if step == 3 {
                    // Ba: wait out the glyph trace + ghost fill so the snapshot
                    // shows the fully drawn letter.
                    Thread.sleep(forTimeInterval: 4.2)
                    snap(app, "05b-guide-ba")
                }
                let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
                let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.65))
                from.press(forDuration: 0.1, thenDragTo: to)
                if step == 0 {
                    snap(app, "05-exercise-draw")
                    // Clear & retry empties the canvas, disabling Check.
                    let clear = app.buttons["clear-retry"]
                    XCTAssertTrue(clear.waitForExistence(timeout: 2), "Clear & retry missing")
                    clear.tap()
                    Thread.sleep(forTimeInterval: 0.4)
                    XCTAssertFalse(check.isEnabled, "Check should disable after clearing")
                    from.press(forDuration: 0.1, thenDragTo: to)
                }
            } else if app.buttons["sound-option-0"].exists {
                app.buttons["sound-option-0"].tap()
                if step == 1 { snap(app, "06-exercise-sound") }
            } else {
                app.buttons["letter-option-0"].tap()
                if step == 2 { snap(app, "07-exercise-articulation") }
            }

            XCTAssertTrue(check.isEnabled, "Check disabled at step \(step)")
            check.tap()
            XCTAssertTrue(proceed.waitForExistence(timeout: 3), "Feedback banner missing at step \(step)")
            if step == 0 {
                snap(app, "08-feedback-banner")
                // Clear & retry stays tappable under the banner: it dismisses
                // the feedback and allows another attempt at the same letter.
                app.buttons["clear-retry"].tap()
                Thread.sleep(forTimeInterval: 0.6)
                XCTAssertFalse(proceed.exists, "Banner should dismiss on Clear & retry")
                let from = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                let to = app.coordinate(withNormalizedOffset: CGVector(dx: 0.52, dy: 0.62))
                from.press(forDuration: 0.1, thenDragTo: to)
                check.tap()
                XCTAssertTrue(proceed.waitForExistence(timeout: 3), "Banner missing after retry")
            }
            proceed.tap()
        }

        // Good job → the two vowel interstitials
        let goodJob = app.staticTexts["Good job!"]
        XCTAssertTrue(goodJob.waitForExistence(timeout: 3))
        snap(app, "09-good-job")
        goodJob.tap()

        let nowVowels = app.staticTexts["Now Letters with Vowels"]
        XCTAssertTrue(nowVowels.waitForExistence(timeout: 3))
        snap(app, "10-vowel-intro")
        nowVowels.tap()

        let listen = app.staticTexts["Listen carefully and repeat"].firstMatch
        XCTAssertTrue(listen.waitForExistence(timeout: 3))
        listen.tap()

        // Harakat practice for each of the 4 letters
        let repeated = app.buttons["I repeated it"]
        for index in 0..<4 {
            XCTAssertTrue(repeated.waitForExistence(timeout: 3), "Vowel page \(index) missing")
            if index == 0 { snap(app, "11-vowels-practice") }
            repeated.tap()
        }

        // Summary
        let summary = app.staticTexts
            .containing(NSPredicate(format: "label CONTAINS 'MashaAllah'"))
            .firstMatch
        XCTAssertTrue(summary.waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Next lesson"].exists)
        snap(app, "12-summary")
        app.buttons["Main"].tap()

        // Back on the Alphabet tab, Lesson 2 is now unlocked.
        XCTAssertTrue(app.staticTexts["Jeem Ha Kho"].firstMatch.waitForExistence(timeout: 3))
        snap(app, "13-alphabet-after")
    }

    private func snap(_ app: XCUIApplication, _ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let dir = URL(fileURLWithPath: "/tmp/alifbaa-uitest", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? screenshot.pngRepresentation.write(to: dir.appendingPathComponent("\(name).png"))
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
