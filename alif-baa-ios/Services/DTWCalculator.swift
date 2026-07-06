//
//  DTWCalculator.swift
//  alif-baa-ios
//
//  Dynamic Time Warping in pure Swift (§5.2): compares a drawn trajectory to a
//  bundled reference without ML or a server. O(n·m) with two rolling rows —
//  well under the 50 ms budget for 64-point trajectories (§5.5).
//

import Foundation
import CoreGraphics

enum DTWCalculator {

    /// DTW distance between two trajectories, normalized by the longer length,
    /// so values are comparable across sample counts. 0 = identical.
    static func distance(_ a: [CGPoint], _ b: [CGPoint]) -> Double {
        guard !a.isEmpty, !b.isEmpty else { return .infinity }
        let n = a.count
        let m = b.count

        var prev = [Double](repeating: .infinity, count: m + 1)
        var curr = [Double](repeating: .infinity, count: m + 1)
        prev[0] = 0

        for i in 1...n {
            curr[0] = .infinity
            for j in 1...m {
                let cost = Double(hypot(a[i - 1].x - b[j - 1].x, a[i - 1].y - b[j - 1].y))
                curr[j] = cost + min(prev[j], curr[j - 1], prev[j - 1])
            }
            swap(&prev, &curr)
        }
        return prev[m] / Double(max(n, m))
    }
}
