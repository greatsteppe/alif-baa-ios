//
//  StrokeNormalizer.swift
//  alif-baa-ios
//
//  Prepares drawn trajectories for DTW comparison (§5.2): points are normalized
//  to the unit square (aspect preserved, centered) and resampled evenly by arc length.
//

import Foundation
import CoreGraphics

enum StrokeNormalizer {

    /// Normalizes a multi-stroke drawing into a single trajectory in [0,1] × [0,1],
    /// resampled to `sampleCount` points. Strokes are concatenated in drawing order,
    /// which is applied identically to user input and reference data.
    static func normalize(_ strokes: [[CGPoint]], sampleCount: Int = 64) -> [CGPoint] {
        let all = strokes.flatMap { $0 }
        guard all.count > 1 else { return all.map { _ in CGPoint(x: 0.5, y: 0.5) } }

        let (minP, maxP) = boundingBox(of: all)
        let width = maxP.x - minP.x
        let height = maxP.y - minP.y
        let scale = max(width, height)

        let unit: [CGPoint]
        if scale <= 0 {
            unit = all.map { _ in CGPoint(x: 0.5, y: 0.5) }
        } else {
            // Aspect-preserving scale, centered in the unit square.
            let xInset = (scale - width) / 2
            let yInset = (scale - height) / 2
            unit = all.map {
                CGPoint(x: ($0.x - minP.x + xInset) / scale,
                        y: ($0.y - minP.y + yInset) / scale)
            }
        }
        return resample(unit, count: sampleCount)
    }

    /// Even arc-length resampling of a polyline.
    static func resample(_ points: [CGPoint], count: Int) -> [CGPoint] {
        guard points.count > 1, count > 1 else { return points }

        var lengths: [CGFloat] = [0]
        for i in 1..<points.count {
            lengths.append(lengths[i - 1] + distance(points[i - 1], points[i]))
        }
        let total = lengths.last ?? 0
        guard total > 0 else { return Array(repeating: points[0], count: count) }

        var result: [CGPoint] = []
        result.reserveCapacity(count)
        var segment = 1
        for i in 0..<count {
            let target = total * CGFloat(i) / CGFloat(count - 1)
            while segment < points.count - 1 && lengths[segment] < target {
                segment += 1
            }
            let segStart = lengths[segment - 1]
            let segLen = lengths[segment] - segStart
            let t = segLen > 0 ? (target - segStart) / segLen : 0
            let a = points[segment - 1]
            let b = points[segment]
            result.append(CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t))
        }
        return result
    }

    static func boundingBox(of points: [CGPoint]) -> (min: CGPoint, max: CGPoint) {
        var minP = CGPoint(x: CGFloat.greatestFiniteMagnitude, y: CGFloat.greatestFiniteMagnitude)
        var maxP = CGPoint(x: -CGFloat.greatestFiniteMagnitude, y: -CGFloat.greatestFiniteMagnitude)
        for p in points {
            minP.x = min(minP.x, p.x); minP.y = min(minP.y, p.y)
            maxP.x = max(maxP.x, p.x); maxP.y = max(maxP.y, p.y)
        }
        return (minP, maxP)
    }

    static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        hypot(a.x - b.x, a.y - b.y)
    }
}
