//
//  LetterGuideView.swift
//  alif-baa-ios
//
//  Animated tracing guide for the Draw exercise (§4.2 A): the reference
//  strokes draw themselves onto the canvas like handwriting, then the
//  letter's sound plays. Letters without authored reference strokes fall
//  back to the static ghosted glyph.
//

import SwiftUI

struct LetterGuideView: View {
    let letter: Letter
    let size: CGSize

    @State private var progress: Double = 0
    @State private var didReveal = false

    private var unitStrokes: [[CGPoint]] {
        ReferenceStrokeStore.strokes(for: letter.arabic) ?? []
    }

    var body: some View {
        Group {
            if unitStrokes.isEmpty {
                ArabicText(
                    text: letter.arabic,
                    size: max(120, min(size.width, size.height) * 0.55),
                    color: AB.neutral300.opacity(0.8)
                )
            } else {
                GuideShape(unitStrokes: unitStrokes, progress: progress)
                    .stroke(
                        AB.neutral300.opacity(0.9),
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear(perform: revealIfReady)
        .onChange(of: size) { revealIfReady() }
    }

    private var lineWidth: CGFloat {
        min(max(min(size.width, size.height) * 0.065, 12), 26)
    }

    private func revealIfReady() {
        guard !didReveal, size.width > 0, size.height > 0 else { return }
        didReveal = true

        guard !unitStrokes.isEmpty else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile)
            }
            return
        }

        let total = GuideShape.totalPacedLength(unitStrokes, in: size)
        let duration = min(max(Double(total / GuideShape.drawSpeed), 1.1), 3.0)
        withAnimation(.linear(duration: duration).delay(0.35), completionCriteria: .logicallyComplete) {
            progress = 1
        } completion: {
            AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile)
        }
    }
}

/// Draws the reference polylines up to `progress` (0…1 of the total paced
/// length), at constant pen speed across strokes, in authored order.
struct GuideShape: Shape {
    let unitStrokes: [[CGPoint]]
    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    /// Handwriting speed, canvas points per second.
    static let drawSpeed: CGFloat = 340
    /// Strokes shorter than this are dots: they pop in whole under a round cap.
    private static let dotThreshold: CGFloat = 20
    /// Pacing beat a dot occupies so the pen visibly "rests" on it.
    private static let dotBeat: CGFloat = 50

    func path(in rect: CGRect) -> Path {
        let strokes = Self.fitted(unitStrokes, in: rect)
        let paced = strokes.map(Self.pacedLength)
        var budget = paced.reduce(0, +) * progress
        var path = Path()

        for (stroke, allowance) in zip(strokes, paced) {
            guard budget > 0, let first = stroke.first else { break }
            let actual = Self.actualLength(stroke)
            if actual < Self.dotThreshold {
                path.move(to: first)
                path.addLine(to: CGPoint(x: first.x + 0.1, y: first.y))
            } else {
                Self.appendPartial(of: stroke, upTo: min(budget, actual), to: &path)
            }
            budget -= allowance
        }
        return path
    }

    static func totalPacedLength(_ unitStrokes: [[CGPoint]], in size: CGSize) -> CGFloat {
        fitted(unitStrokes, in: CGRect(origin: .zero, size: size))
            .map(pacedLength)
            .reduce(0, +)
    }

    /// Unit-square strokes aspect-fit into a centered square of the rect.
    private static func fitted(_ unit: [[CGPoint]], in rect: CGRect) -> [[CGPoint]] {
        let side = min(rect.width, rect.height) * 0.8
        let origin = CGPoint(x: rect.midX - side / 2, y: rect.midY - side / 2)
        return unit.map { stroke in
            stroke.map { CGPoint(x: origin.x + $0.x * side, y: origin.y + $0.y * side) }
        }
    }

    private static func pacedLength(_ stroke: [CGPoint]) -> CGFloat {
        let actual = actualLength(stroke)
        return actual < dotThreshold ? dotBeat : actual
    }

    private static func actualLength(_ stroke: [CGPoint]) -> CGFloat {
        zip(stroke, stroke.dropFirst()).reduce(0) { sum, pair in
            sum + hypot(pair.1.x - pair.0.x, pair.1.y - pair.0.y)
        }
    }

    private static func appendPartial(of stroke: [CGPoint], upTo target: CGFloat, to path: inout Path) {
        guard let first = stroke.first else { return }
        path.move(to: first)
        var traveled: CGFloat = 0
        var previous = first
        for point in stroke.dropFirst() {
            let segment = hypot(point.x - previous.x, point.y - previous.y)
            if traveled + segment <= target || segment == 0 {
                path.addLine(to: point)
                traveled += segment
            } else {
                let t = (target - traveled) / segment
                path.addLine(to: CGPoint(
                    x: previous.x + (point.x - previous.x) * t,
                    y: previous.y + (point.y - previous.y) * t
                ))
                return
            }
            previous = point
        }
    }
}
