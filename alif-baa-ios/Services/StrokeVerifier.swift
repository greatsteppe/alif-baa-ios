//
//  StrokeVerifier.swift
//  alif-baa-ios
//
//  Decides whether a traced letter passes (§4.2 A, §5.2). DTW against bundled
//  reference strokes replaces the prototype's coverage heuristic while keeping
//  its lenient/strict switch; the heuristic remains as the lenient fallback.
//

import Foundation
import CoreGraphics

struct StrokeVerdict {
    let passed: Bool
    let dtwDistance: Double?
}

enum StrokeVerifier {

    /// DTW pass thresholds (§5.2): ≈0.18 strict; lenient is looser.
    static let strictThreshold = 0.18
    static let lenientThreshold = 0.35

    /// Lenient mode is the default for beginners (§5.2).
    static func verify(strokes: [[CGPoint]], canvasSize: CGSize, letterArabic: String, strict: Bool) -> StrokeVerdict {
        guard !strokes.isEmpty else { return StrokeVerdict(passed: false, dtwDistance: nil) }

        guard let reference = ReferenceStrokeStore.strokes(for: letterArabic), !reference.isEmpty else {
            // No reference authored yet — prototype coverage heuristic only.
            return StrokeVerdict(passed: !strict && passesCoverage(strokes: strokes, canvasSize: canvasSize),
                                 dtwDistance: nil)
        }

        // Dots are tiny strokes; lenient matching compares main strokes only,
        // so a learner who skips the dots can still pass.
        let refMain = mainStrokes(of: reference)
        let userMain = mainStrokes(of: strokes)

        let refTrajectory = StrokeNormalizer.normalize(refMain)
        let userTrajectory = StrokeNormalizer.normalize(userMain)
        let dtw = DTWCalculator.distance(userTrajectory, refTrajectory)

        if strict {
            let passed = dtw < strictThreshold && strokes.count == reference.count
            return StrokeVerdict(passed: passed, dtwDistance: dtw)
        }
        let passed = dtw < lenientThreshold
            || passesCoverage(strokes: strokes, canvasSize: canvasSize)
        return StrokeVerdict(passed: passed, dtwDistance: dtw)
    }

    /// Strokes that are not dots (bbox diagonal ≥ 12% of the drawing's diagonal).
    private static func mainStrokes(of strokes: [[CGPoint]]) -> [[CGPoint]] {
        let all = strokes.flatMap { $0 }
        guard all.count > 1 else { return strokes }
        let (minP, maxP) = StrokeNormalizer.boundingBox(of: all)
        let overallDiag = StrokeNormalizer.distance(minP, maxP)
        guard overallDiag > 0 else { return strokes }

        let main = strokes.filter { stroke in
            guard stroke.count > 1 else { return false }
            let (a, b) = StrokeNormalizer.boundingBox(of: stroke)
            return StrokeNormalizer.distance(a, b) / overallDiag >= 0.12
        }
        return main.isEmpty ? strokes : main
    }

    /// Prototype heuristic: enough points, enough of the canvas covered (§4.2 A).
    private static func passesCoverage(strokes: [[CGPoint]], canvasSize: CGSize) -> Bool {
        let all = strokes.flatMap { $0 }
        guard all.count >= 20, canvasSize.width > 0, canvasSize.height > 0 else { return false }
        let (minP, maxP) = StrokeNormalizer.boundingBox(of: all)
        let relW = (maxP.x - minP.x) / canvasSize.width
        let relH = (maxP.y - minP.y) / canvasSize.height
        // A single letter can be tall-and-thin (alif), so one dominant axis suffices.
        return max(relW, relH) >= 0.3
    }
}

// MARK: - Bundled reference strokes

/// Loads ReferenceStrokes.json — hand-authored polylines per isolated letter form,
/// in unit-square coordinates. Production data is authored by a person (§7.1).
enum ReferenceStrokeStore {

    nonisolated(unsafe) private static var cache: [String: [[CGPoint]]]?

    static func all() -> [String: [[CGPoint]]] {
        if let cache { return cache }
        var result: [String: [[CGPoint]]] = [:]
        if let url = Bundle.main.url(forResource: "ReferenceStrokes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let object = try? JSONSerialization.jsonObject(with: data) as? [String: [[[Double]]]] {
            for (letter, strokes) in object {
                result[letter] = strokes.map { stroke in
                    stroke.compactMap { pair in
                        pair.count >= 2 ? CGPoint(x: pair[0], y: pair[1]) : nil
                    }
                }
            }
        }
        cache = result
        return result
    }

    static func strokes(for letterArabic: String) -> [[CGPoint]]? {
        all()[letterArabic]
    }

    /// Raw per-letter JSON strings for seeding LetterForm.strokeDataJSON (§5.4).
    static func loadRaw() -> [String: String] {
        var raw: [String: String] = [:]
        for (letter, strokes) in all() {
            let array = strokes.map { $0.map { [Double($0.x), Double($0.y)] } }
            if let data = try? JSONSerialization.data(withJSONObject: array),
               let json = String(data: data, encoding: .utf8) {
                raw[letter] = json
            }
        }
        return raw
    }
}
