//
//  StrokeInputView.swift
//  alif-baa-ios
//
//  PencilKit canvas for finger tracing (§5.1 — no Pencil required). Streams the
//  drawn strokes out as point arrays for the DTW verifier.
//

import SwiftUI
import PencilKit
import UIKit

struct StrokeInputView: UIViewRepresentable {
    @Binding var strokes: [[CGPoint]]
    var clearTrigger: Int

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = PKCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.backgroundColor = .clear
        canvas.isOpaque = false
        canvas.isScrollEnabled = false
        canvas.tool = PKInkingTool(.pen, color: UIColor(AB.primary), width: 18)
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ canvas: PKCanvasView, context: Context) {
        if context.coordinator.lastClearTrigger != clearTrigger {
            context.coordinator.lastClearTrigger = clearTrigger
            canvas.drawing = PKDrawing()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: StrokeInputView
        var lastClearTrigger = 0

        init(_ parent: StrokeInputView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.strokes = canvasView.drawing.strokes.map { stroke in
                stroke.path
                    .interpolatedPoints(by: .distance(4))
                    .map { $0.location.applying(stroke.transform) }
            }
        }
    }
}
