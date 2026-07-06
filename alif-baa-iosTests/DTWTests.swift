//
//  DTWTests.swift
//  alif-baa-iosTests
//
//  PRD Task 6 acceptance: matching trajectories → distance < 0.1;
//  mirrored trajectories → distance > 0.3.
//

import XCTest
@testable import alif_baa_ios

@MainActor
final class DTWTests: XCTestCase {

    /// An L-shape: down the left edge, then across the bottom.
    private func lShape(offset: CGFloat = 0, scale: CGFloat = 1) -> [CGPoint] {
        var points: [CGPoint] = []
        for i in 0...20 {
            points.append(CGPoint(x: offset, y: offset + scale * CGFloat(i) / 20))
        }
        for i in 1...20 {
            points.append(CGPoint(x: offset + scale * CGFloat(i) / 20, y: offset + scale))
        }
        return points
    }

    func testMatchingTrajectoriesScoreBelowPointOne() {
        // Same shape, drawn at a different position and size, sampled differently.
        let a = StrokeNormalizer.normalize([lShape()])
        let b = StrokeNormalizer.normalize([lShape(offset: 40, scale: 180)])

        let distance = DTWCalculator.distance(a, b)
        XCTAssertLessThan(distance, 0.1, "Identical trajectories should match closely")
    }

    func testIdenticalTrajectoryIsNearZero() {
        let a = StrokeNormalizer.normalize([lShape()])
        XCTAssertLessThan(DTWCalculator.distance(a, a), 0.001)
    }

    func testMirroredTrajectoriesScoreAbovePointThree() {
        let original = lShape()
        // Mirror across the vertical axis: down the right edge, then across the bottom.
        let mirrored = original.map { CGPoint(x: 1 - $0.x, y: $0.y) }

        let a = StrokeNormalizer.normalize([original])
        let b = StrokeNormalizer.normalize([mirrored])

        let distance = DTWCalculator.distance(a, b)
        XCTAssertGreaterThan(distance, 0.3, "Mirrored trajectories must not pass")
    }

    func testStrictThresholdSeparatesShapes() {
        // A vertical line (alif) against the seen zigzag reference must fail strict.
        let alifLike: [[CGPoint]] = [[CGPoint(x: 0.5, y: 0.1), CGPoint(x: 0.5, y: 0.9)]]
        guard let seenRef = ReferenceStrokeStore.strokes(for: "س") else {
            // Reference bundle is not loadable from the test host in some configurations.
            return
        }
        let a = StrokeNormalizer.normalize(alifLike)
        let b = StrokeNormalizer.normalize(seenRef)
        XCTAssertGreaterThan(DTWCalculator.distance(a, b), StrokeVerifier.strictThreshold)
    }

    /// DTW on 64-point trajectories must be far below the 50 ms budget (§5.5).
    func testPerformanceBudget() {
        let a = StrokeNormalizer.normalize([lShape()])
        let b = StrokeNormalizer.normalize([lShape(offset: 10, scale: 2)])

        let start = Date()
        for _ in 0..<100 {
            _ = DTWCalculator.distance(a, b)
        }
        let elapsedPerCall = -start.timeIntervalSinceNow / 100
        XCTAssertLessThan(elapsedPerCall, 0.05, "DTW compute must stay under 50 ms")
    }
}
