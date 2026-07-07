//
//  LetterGuideView.swift
//  alif-baa-ios
//
//  Animated tracing guide for the Draw exercise (§4.2 A): the letter appears
//  as one solid pen line, the pen traveling each stroke's centerline exactly
//  once the way Arabic is written — right to left, base stroke first, dots
//  after — using the letter's real font glyph (Noto Sans Arabic), then the
//  letter's sound plays. Letters whose glyph can't be extracted fall back to
//  the static ghosted glyph.
//

import SwiftUI
import UIKit
import CoreText

struct LetterGuideView: View {
    let letter: Letter
    let size: CGSize

    @State private var trace: Double = 0
    @State private var settled = false
    @State private var didReveal = false

    private var glyph: ArabicGlyphOutline.Glyph? {
        ArabicGlyphOutline.glyph(for: letter.arabic)
    }

    var body: some View {
        Group {
            if let glyph {
                GlyphFillShape(glyph: glyph.fill, box: glyph.box)
                    .fill(AB.neutral300.opacity(0.8))
                    .mask {
                        ZStack {
                            // A thick round pen sweeping the writing line
                            // uncovers the solid letter as it goes.
                            PenStrokeShape(pen: glyph.pen, box: glyph.box, progress: trace)
                                .stroke(style: StrokeStyle(
                                    lineWidth: min(size.width, size.height) * 0.15,
                                    lineCap: .round,
                                    lineJoin: .round
                                ))
                            if settled {
                                Rectangle()   // guarantees the finished letter is complete
                            }
                        }
                    }
            } else {
                ArabicText(
                    text: letter.arabic,
                    size: max(120, min(size.width, size.height) * 0.55),
                    color: AB.neutral300.opacity(0.8)
                )
            }
        }
        .allowsHitTesting(false)
        .onAppear(perform: revealIfReady)
        .onChange(of: size) { revealIfReady() }
    }

    private func revealIfReady() {
        guard !didReveal, size.width > 0, size.height > 0 else { return }
        didReveal = true

        guard let glyph else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile)
            }
            return
        }

        // Pen speed along the writing line, canvas points per second —
        // unhurried, so the eye can follow the right-to-left motion.
        let side = min(size.width, size.height) * 0.8
        let scale = min(side / glyph.box.width, side / glyph.box.height)
        let duration = min(max(Double(glyph.penLength * scale) / 320, 2), 3.5)
        withAnimation(.linear(duration: duration).delay(0.35), completionCriteria: .logicallyComplete) {
            trace = 1
        } completion: {
            withAnimation(.easeOut(duration: 0.2)) { settled = true }
            AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile)
        }
    }
}

/// The letter as the font fills it, aspect-fit into a centered square.
struct GlyphFillShape: Shape {
    let glyph: CGPath
    let box: CGRect

    func path(in rect: CGRect) -> Path {
        GlyphFit.fit(glyph, box: box, in: rect)
    }
}

/// The writing line revealed up to `progress` (0…1 of its length).
struct PenStrokeShape: Shape {
    let pen: CGPath
    let box: CGRect
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let fitted = GlyphFit.fit(pen, box: box, in: rect)
        return progress >= 1 ? fitted : fitted.trimmedPath(from: 0, to: progress)
    }
}

enum GlyphFit {
    /// Aspect-fit a path into a centered square covering 80 % of the rect's
    /// short side. `box` is the fill glyph's bounds so the pen line and the
    /// fill land on exactly the same spot.
    static func fit(_ path: CGPath, box: CGRect, in rect: CGRect) -> Path {
        guard box.width > 0, box.height > 0, rect.width > 0, rect.height > 0 else { return Path() }
        let side = min(rect.width, rect.height) * 0.8
        let scale = min(side / box.width, side / box.height)
        let transform = CGAffineTransform(
            translationX: rect.midX - box.midX * scale,
            y: rect.midY - box.midY * scale
        ).scaledBy(x: scale, y: scale)
        return Path(path).applying(transform)
    }
}

/// Extracts and caches the letter's outline from the app's Arabic face
/// (Noto Sans Arabic, system cascade fallback), plus the "pen" line the
/// reveal follows: the centerline of every stroke, traveled once like a real
/// pen — simple strokes are the outline folded in half between its two caps,
/// looped strokes (ص ط ف م و …) are a ring around the counter followed by
/// the centerlines of their tails.
@MainActor
enum ArabicGlyphOutline {
    struct Glyph {
        let fill: CGPath        // what the letter looks like
        let pen: CGPath         // the writing line the reveal follows
        let box: CGRect         // fill bounds; both paths are fit with it
        let penLength: CGFloat  // in glyph units, for the trace duration
    }

    private struct PenPiece {
        var points: [CGPoint]
        var closed: Bool
    }

    private static var cache: [String: Glyph] = [:]

    static func glyph(for text: String) -> Glyph? {
        if let cached = cache[text] { return cached }

        // Same face ArabicText renders with; the cascade guarantees a font
        // that actually contains the string's glyphs.
        let base: CTFont
        if UIFont(name: AB.arabicFontName, size: 256) != nil {
            base = CTFontCreateWithName(AB.arabicFontName as CFString, 256, nil)
        } else {
            base = CTFontCreateUIFontForLanguage(.system, 256, nil)
                ?? CTFontCreateWithName("GeezaPro" as CFString, 256, nil)
        }
        let font = CTFontCreateForString(base, text as CFString, CFRange(location: 0, length: (text as NSString).length))

        let characters = Array(text.utf16)
        var glyphs = [CGGlyph](repeating: 0, count: characters.count)
        guard CTFontGetGlyphsForCharacters(font, characters, &glyphs, characters.count) else { return nil }

        let outline = CGMutablePath()
        var offset: CGFloat = 0
        for var glyph in glyphs where glyph != 0 {
            var advance = CGSize.zero
            CTFontGetAdvancesForGlyphs(font, .horizontal, &glyph, &advance, 1)
            var transform = CGAffineTransform(translationX: offset, y: 0)
            if let path = CTFontCreatePathForGlyph(font, glyph, &transform) {
                outline.addPath(path)
            }
            offset += advance.width
        }
        guard !outline.isEmpty else { return nil }

        // Font space is y-up; flip once so shapes can fit it directly.
        var flip = CGAffineTransform(scaleX: 1, y: -1)
        let flipped = outline.copy(using: &flip) ?? outline

        let pieces = penPieces(of: flipped)
        guard !pieces.isEmpty else { return nil }

        let pen = CGMutablePath()
        var penLength: CGFloat = 0
        for piece in pieces {
            pen.move(to: piece.points[0])
            for point in piece.points.dropFirst() {
                pen.addLine(to: point)
            }
            if piece.closed { pen.closeSubpath() }
            penLength += polylineLength(piece.points, closed: piece.closed)
        }

        let glyph = Glyph(fill: flipped, pen: pen, box: flipped.boundingBoxOfPath, penLength: penLength)
        cache[text] = glyph
        return glyph
    }

    // MARK: - Pen path construction

    /// The full pen path: one centerline pass per stroke, ordered like
    /// handwriting — base stroke first, then dots/marks right to left.
    private static func penPieces(of path: CGPath) -> [PenPiece] {
        let contours = flattenedContours(of: path).compactMap { uniform($0) }
        guard !contours.isEmpty else { return [] }

        // Every contour is either a stroke's outer boundary or a hole in one.
        let areas = contours.map(area)
        let centers = contours.map(centroid)
        var holesOf: [Int: [Int]] = [:]
        var isHole = [Bool](repeating: false, count: contours.count)
        for i in contours.indices {
            var parent: Int?
            for j in contours.indices
            where j != i && areas[j] > areas[i] && contains(contours[j], centers[i]) {
                if parent == nil || areas[j] < areas[parent!] { parent = j }
            }
            if let parent {
                holesOf[parent, default: []].append(i)
                isHole[i] = true
            }
        }

        var groups: [[PenPiece]] = []
        for i in contours.indices where !isHole[i] {
            let holes = (holesOf[i] ?? []).map { contours[$0] }
            if holes.isEmpty {
                groups.append([PenPiece(points: foldCenterline(contours[i]), closed: false)])
            } else {
                var rings = holes.map {
                    PenPiece(points: ringMidline(hole: $0, outer: contours[i]), closed: true)
                }
                rings.sort { maxX($0.points) > maxX($1.points) }
                var tails = tailCenterlines(outer: contours[i], holes: holes)
                    .map { PenPiece(points: $0, closed: false) }
                tails.sort { maxX($0.points) > maxX($1.points) }
                groups.append(rings + tails)
            }
        }
        groups = groups.map { $0.filter { $0.points.count > 1 } }.filter { !$0.isEmpty }
        guard groups.count > 1 else { return groups.first ?? [] }

        func total(_ group: [PenPiece]) -> CGFloat {
            group.reduce(0) { $0 + polylineLength($1.points, closed: $1.closed) }
        }
        var bodyIndex = 0
        for gi in groups.indices where total(groups[gi]) > total(groups[bodyIndex]) { bodyIndex = gi }
        let body = groups.remove(at: bodyIndex)
        groups.sort { g, h in
            (g.map { maxX($0.points) }.max() ?? 0) > (h.map { maxX($0.points) }.max() ?? 0)
        }
        return body + groups.flatMap { $0 }
    }

    /// Centerline of a simple (hole-free) stroke: the outline folded in half
    /// between its two caps, midpoints of opposite sides.
    private static func foldCenterline(_ loop: [CGPoint]) -> [CGPoint] {
        let n = loop.count
        guard n >= 8 else { return loop }
        var s = 0
        for i in loop.indices
        where loop[i].x > loop[s].x || (loop[i].x == loop[s].x && loop[i].y < loop[s].y) {
            s = i
        }
        var e = s
        var far: CGFloat = -1
        for i in loop.indices {
            let d = dist(loop[i], loop[s])
            if d > far { far = d; e = i }
        }
        guard e != s else { return loop }
        var sideA: [CGPoint] = []
        var i = s
        while true { sideA.append(loop[i]); if i == e { break }; i = (i + 1) % n }
        var sideB: [CGPoint] = []
        i = s
        while true { sideB.append(loop[i]); if i == e { break }; i = (i - 1 + n) % n }
        var line = sideA.count >= sideB.count
            ? pairMidline(guide: sideA, other: sideB)
            : pairMidline(guide: sideB, other: sideA)
        line.append(loop[e])
        return orientedForWriting(line)
    }

    /// Midline of a looped stroke (a ring around a counter): halfway between
    /// the hole's boundary and the nearest outer boundary, drawn from its
    /// rightmost point along the top first.
    private static func ringMidline(hole: [CGPoint], outer: [CGPoint]) -> [CGPoint] {
        var loop: [CGPoint] = []
        for h in hole {
            var best = outer[0]
            var bd = CGFloat.greatestFiniteMagnitude
            for o in outer where dist(h, o) < bd { bd = dist(h, o); best = o }
            loop.append(mid(h, best))
        }
        return orientLoop(loop)
    }

    /// Centerlines of the parts of the outer boundary far from any hole —
    /// the tails and bars attached to a looped stroke.
    private static func tailCenterlines(outer: [CGPoint], holes: [[CGPoint]]) -> [[CGPoint]] {
        let holePts = holes.flatMap { $0 }
        guard !holePts.isEmpty else { return [] }
        let d: [CGFloat] = outer.map { o in
            holePts.reduce(CGFloat.greatestFiniteMagnitude) { min($0, dist($1, o)) }
        }
        // Ring stroke width, measured from the hole's side so a long tail
        // can't skew it: the median hole-to-outer distance.
        let holeToOuter = holePts.map { h in
            outer.reduce(CGFloat.greatestFiniteMagnitude) { min($0, dist($1, h)) }
        }.sorted()
        let ringDist = holeToOuter[holeToOuter.count / 2]
        let threshold = ringDist * 1.6
        guard let anchor = d.indices.min(by: { d[$0] < d[$1] }) else { return [] }
        let n = outer.count

        var runs: [[Int]] = []
        var run: [Int] = []
        for k in 1...n {
            let i = (anchor + k) % n
            if d[i] > threshold {
                run.append(i)
            } else if !run.isEmpty {
                runs.append(run)
                run = []
            }
        }
        if !run.isEmpty { runs.append(run) }

        var lines: [[CGPoint]] = []
        for run in runs {
            let pts = run.map { outer[$0] }
            guard pts.count >= 8, polylineLength(pts, closed: false) > ringDist * 4 else { continue }
            var cap = 0
            for k in pts.indices where d[run[k]] > d[run[cap]] { cap = k }
            cap = min(max(cap, 1), pts.count - 2)
            let legA = Array(pts[0...cap])
            let legB = Array(pts[cap...].reversed())
            var line = legA.count >= legB.count
                ? pairMidline(guide: legA, other: legB)
                : pairMidline(guide: legB, other: legA)
            line.append(pts[cap])
            lines.append(orientedForWriting(line))
        }
        return lines
    }

    /// Walks a monotonic cursor over `other`, pairing each guide point with
    /// its nearest opposite point; midpoints approximate the centerline.
    private static func pairMidline(guide: [CGPoint], other: [CGPoint]) -> [CGPoint] {
        guard !other.isEmpty else { return guide }
        var j = 0
        var line: [CGPoint] = []
        for g in guide {
            while j + 1 < other.count && dist(other[j + 1], g) <= dist(other[j], g) { j += 1 }
            line.append(mid(g, other[j]))
        }
        return line
    }

    /// Starts a line from its higher-right end — where an Arabic pen starts.
    private static func orientedForWriting(_ line: [CGPoint]) -> [CGPoint] {
        guard let f = line.first, let l = line.last, (l.x - l.y) > (f.x - f.y) else { return line }
        return line.reversed()
    }

    /// Restarts a closed loop at its rightmost point, running its upper side
    /// first — the pen direction of Arabic handwriting.
    private static func orientLoop(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count > 2 else { return points }
        var start = 0
        for index in points.indices
        where (points[index].x, -points[index].y) > (points[start].x, -points[start].y) {
            start = index
        }
        let rotated = Array(points[start...] + points[..<start])
        let quarter = max(2, rotated.count / 4)
        let reversed = [rotated[0]] + rotated.dropFirst().reversed()
        let forwardY = rotated[1...quarter].reduce(0) { $0 + $1.y }
        let backwardY = reversed[1...quarter].reduce(0) { $0 + $1.y }
        return backwardY < forwardY ? reversed : rotated
    }

    // MARK: - Outline flattening

    /// Flattens the outline into closed polylines (curves sampled as chords).
    private static func flattenedContours(of path: CGPath) -> [[CGPoint]] {
        var contours: [[CGPoint]] = []
        var current: [CGPoint] = []

        path.applyWithBlock { element in
            let e = element.pointee
            let p = e.points

            func addSamples(_ point: (CGFloat) -> CGPoint) {
                for i in 1...12 { current.append(point(CGFloat(i) / 12)) }
            }

            switch e.type {
            case .moveToPoint:
                if current.count > 2 { contours.append(current) }
                current = [p[0]]
            case .addLineToPoint:
                current.append(p[0])
            case .addQuadCurveToPoint:
                guard let s = current.last else { break }
                let c = p[0], to = p[1]
                addSamples { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u*u * s.x + 2*u*t * c.x + t*t * to.x,
                        y: u*u * s.y + 2*u*t * c.y + t*t * to.y
                    )
                }
            case .addCurveToPoint:
                guard let s = current.last else { break }
                let c1 = p[0], c2 = p[1], to = p[2]
                addSamples { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u*u*u * s.x + 3*u*u*t * c1.x + 3*u*t*t * c2.x + t*t*t * to.x,
                        y: u*u*u * s.y + 3*u*u*t * c1.y + 3*u*t*t * c2.y + t*t*t * to.y
                    )
                }
            case .closeSubpath:
                if current.count > 2 { contours.append(current) }
                current = []
            @unknown default:
                break
            }
        }
        if current.count > 2 { contours.append(current) }
        return contours
    }

    /// Resamples a closed contour to uniform spacing (glyph units, size 256).
    private static func uniform(_ contour: [CGPoint], spacing: CGFloat = 3) -> [CGPoint]? {
        guard contour.count > 2 else { return nil }
        var pts = contour
        pts.append(contour[0])
        var cum: [CGFloat] = [0]
        for i in 1..<pts.count { cum.append(cum[i - 1] + dist(pts[i - 1], pts[i])) }
        guard let total = cum.last, total > 12 else { return nil }
        let count = max(16, Int(total / spacing))
        var result: [CGPoint] = []
        var j = 0
        for k in 0..<count {
            let target = total * CGFloat(k) / CGFloat(count)
            while j < pts.count - 2 && cum[j + 1] < target { j += 1 }
            let seg = cum[j + 1] - cum[j]
            result.append(lerp(pts[j], pts[j + 1], seg > 0 ? (target - cum[j]) / seg : 0))
        }
        return result
    }

    // MARK: - Geometry

    private static func dist(_ a: CGPoint, _ b: CGPoint) -> CGFloat { hypot(a.x - b.x, a.y - b.y) }

    private static func mid(_ a: CGPoint, _ b: CGPoint) -> CGPoint {
        CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
    }

    private static func lerp(_ a: CGPoint, _ b: CGPoint, _ t: CGFloat) -> CGPoint {
        CGPoint(x: a.x + (b.x - a.x) * t, y: a.y + (b.y - a.y) * t)
    }

    private static func polylineLength(_ points: [CGPoint], closed: Bool) -> CGFloat {
        guard points.count > 1 else { return 0 }
        var total: CGFloat = 0
        for i in 1..<points.count { total += dist(points[i], points[i - 1]) }
        if closed, let f = points.first, let l = points.last { total += dist(f, l) }
        return total
    }

    private static func maxX(_ points: [CGPoint]) -> CGFloat {
        points.reduce(-.greatestFiniteMagnitude) { max($0, $1.x) }
    }

    private static func area(_ points: [CGPoint]) -> CGFloat {
        guard points.count > 2 else { return 0 }
        var sum: CGFloat = 0
        for i in points.indices {
            let a = points[i], b = points[(i + 1) % points.count]
            sum += a.x * b.y - b.x * a.y
        }
        return abs(sum) / 2
    }

    private static func centroid(_ points: [CGPoint]) -> CGPoint {
        var c = CGPoint.zero
        for p in points { c.x += p.x; c.y += p.y }
        return CGPoint(x: c.x / CGFloat(points.count), y: c.y / CGFloat(points.count))
    }

    /// Even-odd point-in-polygon test.
    private static func contains(_ poly: [CGPoint], _ p: CGPoint) -> Bool {
        var inside = false
        var j = poly.count - 1
        for i in poly.indices {
            if (poly[i].y > p.y) != (poly[j].y > p.y),
               p.x < (poly[j].x - poly[i].x) * (p.y - poly[i].y) / (poly[j].y - poly[i].y) + poly[i].x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }
}
