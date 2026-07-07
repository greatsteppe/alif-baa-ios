//
//  LetterGuideView.swift
//  alif-baa-ios
//
//  Animated tracing guide for the Draw exercise (§4.2 A): the letter's real
//  font glyph (Noto Sans Arabic) outlines itself like handwriting, ghost-fills,
//  then the letter's sound plays. Letters whose glyph can't be extracted fall
//  back to the static ghosted glyph.
//

import SwiftUI
import UIKit
import CoreText

struct LetterGuideView: View {
    let letter: Letter
    let size: CGSize

    @State private var trace: Double = 0
    @State private var fillIn: Double = 0
    @State private var didReveal = false

    private var glyph: CGPath? {
        ArabicGlyphOutline.path(for: letter.arabic)
    }

    var body: some View {
        Group {
            if let glyph {
                ZStack {
                    GlyphShape(glyph: glyph, progress: 1)
                        .fill(AB.neutral300.opacity(0.8))
                        .opacity(fillIn)
                    GlyphShape(glyph: glyph, progress: trace)
                        .stroke(
                            AB.neutral400.opacity(0.7),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )
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

        let outline = GlyphShape.outlineLength(of: glyph, in: size)
        let duration = min(max(Double(outline / GlyphShape.traceSpeed), 1.1), 3.0)
        withAnimation(.linear(duration: duration).delay(0.35), completionCriteria: .logicallyComplete) {
            trace = 1
        } completion: {
            withAnimation(.easeOut(duration: 0.35)) { fillIn = 1 }
            AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile)
        }
    }
}

/// Draws the glyph outline up to `progress` (0…1 of the contour length),
/// aspect-fit into a centered square of the rect.
struct GlyphShape: Shape {
    let glyph: CGPath
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Outline tracing speed, canvas points per second.
    static let traceSpeed: CGFloat = 550

    func path(in rect: CGRect) -> Path {
        let fitted = Self.fitted(glyph, in: rect)
        return progress >= 1 ? fitted : fitted.trimmedPath(from: 0, to: progress)
    }

    static func outlineLength(of glyph: CGPath, in size: CGSize) -> CGFloat {
        length(of: fitted(glyph, in: CGRect(origin: .zero, size: size)))
    }

    /// Glyph bounding box aspect-fit into a centered square of the rect.
    private static func fitted(_ glyph: CGPath, in rect: CGRect) -> Path {
        let box = glyph.boundingBoxOfPath
        guard box.width > 0, box.height > 0, rect.width > 0, rect.height > 0 else { return Path() }
        let side = min(rect.width, rect.height) * 0.8
        let scale = min(side / box.width, side / box.height)
        let transform = CGAffineTransform(
            translationX: rect.midX - box.midX * scale,
            y: rect.midY - box.midY * scale
        ).scaledBy(x: scale, y: scale)
        return Path(glyph).applying(transform)
    }

    /// Approximate arc length; curves are sampled as short chords.
    private static func length(of path: Path) -> CGFloat {
        var total: CGFloat = 0
        var current = CGPoint.zero
        var subpathStart = CGPoint.zero

        func polyline(_ point: (CGFloat) -> CGPoint, samples: Int = 8) -> CGFloat {
            var sum: CGFloat = 0
            var previous = point(0)
            for i in 1...samples {
                let next = point(CGFloat(i) / CGFloat(samples))
                sum += hypot(next.x - previous.x, next.y - previous.y)
                previous = next
            }
            return sum
        }

        path.forEach { element in
            switch element {
            case .move(let to):
                current = to
                subpathStart = to
            case .line(let to):
                total += hypot(to.x - current.x, to.y - current.y)
                current = to
            case .quadCurve(let to, let control):
                let start = current
                total += polyline { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u*u * start.x + 2*u*t * control.x + t*t * to.x,
                        y: u*u * start.y + 2*u*t * control.y + t*t * to.y
                    )
                }
                current = to
            case .curve(let to, let control1, let control2):
                let start = current
                total += polyline { t in
                    let u = 1 - t
                    return CGPoint(
                        x: u*u*u * start.x + 3*u*u*t * control1.x + 3*u*t*t * control2.x + t*t*t * to.x,
                        y: u*u*u * start.y + 3*u*u*t * control1.y + 3*u*t*t * control2.y + t*t*t * to.y
                    )
                }
                current = to
            case .closeSubpath:
                total += hypot(subpathStart.x - current.x, subpathStart.y - current.y)
                current = subpathStart
            }
        }
        return total
    }
}

/// Extracts and caches the outline of a string as drawn by the app's Arabic
/// face (Noto Sans Arabic, system cascade fallback), y-flipped for screen use.
@MainActor
enum ArabicGlyphOutline {
    private static var cache: [String: CGPath] = [:]

    static func path(for text: String) -> CGPath? {
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
        cache[text] = flipped
        return flipped
    }
}
