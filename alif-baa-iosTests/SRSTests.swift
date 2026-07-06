//
//  SRSTests.swift
//  alif-baa-iosTests
//
//  PRD Task 7 acceptance: first answer, failure after a streak,
//  and quality=5 three times.
//

import XCTest
@testable import alif_baa_ios

@MainActor
final class SRSTests: XCTestCase {

    private func freshProgress() -> UserProgress {
        UserProgress(itemType: "letter", itemId: "1")
    }

    func testFirstCorrectAnswer() {
        let progress = freshProgress()

        SRSService.processAnswer(progress, quality: 5)

        XCTAssertEqual(progress.repetition, 1)
        XCTAssertEqual(progress.interval, 1)
        XCTAssertEqual(progress.easeFactor, 2.6, accuracy: 0.0001)
        XCTAssertEqual(progress.correctCount, 1)
        XCTAssertEqual(progress.wrongCount, 0)
        XCTAssertNotNil(progress.nextReviewAt)
    }

    func testFailureAfterStreakResetsRepetition() {
        let progress = freshProgress()
        SRSService.processAnswer(progress, quality: 5)
        SRSService.processAnswer(progress, quality: 5)
        SRSService.processAnswer(progress, quality: 5)
        let easeBeforeFailure = progress.easeFactor
        XCTAssertEqual(progress.repetition, 3)

        SRSService.processAnswer(progress, quality: 2)

        XCTAssertEqual(progress.repetition, 0, "Failure resets the streak")
        XCTAssertEqual(progress.interval, 1, "Item is relearned from a 1-day interval")
        XCTAssertEqual(progress.easeFactor, easeBeforeFailure, accuracy: 0.0001,
                       "SM-2 leaves the ease factor unchanged on failure")
        XCTAssertEqual(progress.wrongCount, 1)
    }

    func testQualityFiveThreeTimes() {
        let progress = freshProgress()

        SRSService.processAnswer(progress, quality: 5)
        XCTAssertEqual(progress.interval, 1)

        SRSService.processAnswer(progress, quality: 5)
        XCTAssertEqual(progress.interval, 6)

        SRSService.processAnswer(progress, quality: 5)

        XCTAssertEqual(progress.repetition, 3)
        XCTAssertEqual(progress.easeFactor, 2.8, accuracy: 0.0001)
        // Third interval: round(6 × 2.8) = 17 days.
        XCTAssertEqual(progress.interval, 17)
    }

    func testIsDue() {
        let progress = freshProgress()
        XCTAssertTrue(SRSService.isDue(progress), "New items are due immediately")

        SRSService.processAnswer(progress, quality: 5)
        XCTAssertFalse(SRSService.isDue(progress), "Reviewed items are not due until nextReviewAt")
        XCTAssertTrue(SRSService.isDue(progress, now: Date().addingTimeInterval(2 * 86_400)))
    }

    func testStatusProgression() {
        XCTAssertEqual(SRSService.status(of: nil), .notStarted)

        let progress = freshProgress()
        XCTAssertEqual(SRSService.status(of: progress), .notStarted)

        // 1 correct, 1 wrong → 50% < 80% → in progress.
        SRSService.processAnswer(progress, quality: 5)
        SRSService.processAnswer(progress, quality: 2)
        XCTAssertEqual(SRSService.status(of: progress), .inProgress)

        // Climb back to 80% accuracy (4 of 5) while the interval is still short.
        for _ in 0..<3 { SRSService.processAnswer(progress, quality: 5) }
        XCTAssertEqual(SRSService.status(of: progress), .learned)

        // Keep reviewing until the interval crosses 30 days → mastered.
        SRSService.processAnswer(progress, quality: 5)
        XCTAssertGreaterThanOrEqual(progress.interval, 30)
        XCTAssertEqual(SRSService.status(of: progress), .mastered)
    }
}
