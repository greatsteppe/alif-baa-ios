//
//  LetterGuideView.swift
//  alif-baa-ios
//
//  Animated tracing guide for the Draw exercise (§4.2 A): the letter appears
//  as one solid pen line drawn right to left — base stroke first, dots after,
//  the way Arabic is written — using the letter's real font glyph (Noto Sans
//  Arabic), then the letter's sound plays. Letters whose glyph can't be
//  extracted fall back to the static ghosted glyph.
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
        let duration = min(max(Double(glyph.penLength * scale) / 320, 1.4), 3.5)
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
/// reveal follows: every contour restarted at its rightmost point running
/// right to left along its top, base stroke before the dots.
@MainActor
enum ArabicGlyphOutline {
    struct Glyph {
        let fill: CGPath        // what the letter looks like
        let pen: CGPath         // the writing line the reveal follows
        let box: CGRect         // fill bounds; both paths are fit with it
        let penLength: CGFloat  // in glyph units, for the trace duration
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

        let contours = penContours(of: flipped)
        guard !contours.isEmpty else { return nil }

        let pen = CGMutablePath()
        var penLength: CGFloat = 0
        for contour in contours {
            pen.move(to: contour[0])
            for point in contour.dropFirst() {
                pen.addLine(to: point)
            }
            pen.closeSubpath()
            penLength += length(of: contour)
        }

        let glyph = Glyph(fill: flipped, pen: pen, box: flipped.boundingBoxOfPath, penLength: penLength)
        cache[text] = glyph
        return glyph
    }

    // MARK: - Pen line construction

    /// Flattens the outline into polylines ordered like handwriting: the
    /// longest contour (the base stroke) leads, the rest (dots) follow right
    /// to left.
    private static func penContours(of path: CGPath) -> [[CGPoint]] {
        var contours: [[CGPoint]] = []
        var current: [CGPoint] = []

        path.applyWithBlock { element in
            let e = element.pointee
            let p = e.points

            func addSamples(_ point: (CGFloat) -> CGPoint) {
                for i in 1...12 {
                    current.append(point(CGFloat(i) / 12))
                }
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

        var ordered = contours.map(rightToLeft)
        guard ordered.count > 1 else { return ordered }

        var bodyIndex = 0
        for index in ordered.indices where length(of: ordered[index]) > length(of: ordered[bodyIndex]) {
            bodyIndex = index
        }
        let body = ordered.remove(at: bodyIndex)
        ordered.sort { maxX($0) > maxX($1) }
        return [body] + ordered
    }

    /// Restarts a closed contour at its rightmost point, running its upper
    /// side first — the pen direction of Arabic handwriting.
    private static func rightToLeft(_ points: [CGPoint]) -> [CGPoint] {
        guard points.count > 2 else { return points }

        var start = 0
        for index in points.indices
        where (points[index].x, -points[index].y) > (points[start].x, -points[start].y) {
            start = index
        }
        let rotated = Array(points[start...] + points[..<start])

        // Of the two ways around the loop, pick the one whose opening leg sits
        // higher (screen y grows downward): the pen draws along the top edge
        // heading left before coming back underneath.
        let quarter = max(2, rotated.count / 4)
        let reversed = [rotated[0]] + rotated.dropFirst().reversed()
        let forwardY = rotated[1...quarter].reduce(0) { $0 + $1.y }
        let backwardY = reversed[1...quarter].reduce(0) { $0 + $1.y }
        return backwardY < forwardY ? reversed : rotated
    }

    /// Polyline length including the closing segment.
    private static func length(of points: [CGPoint]) -> CGFloat {
        guard points.count > 1, let first = points.first, let last = points.last else { return 0 }
        var total: CGFloat = 0
        for index in 1..<points.count {
            total += hypot(points[index].x - points[index - 1].x, points[index].y - points[index - 1].y)
        }
        return total + hypot(first.x - last.x, first.y - last.y)
    }

    private static func maxX(_ points: [CGPoint]) -> CGFloat {
        points.reduce(-.greatestFiniteMagnitude) { max($0, $1.x) }
    }
}
