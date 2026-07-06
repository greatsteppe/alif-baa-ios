//
//  ExerciseViews.swift
//  alif-baa-ios
//
//  The three exercise bodies (§4.2 A–C): Draw on the ghosted canvas,
//  Select-the-sound, and Articulation (select the letter for a sound).
//

import SwiftUI

struct ExerciseStepView: View {
    let step: ExerciseStep
    let strict: Bool
    let locked: Bool
    let onAnswer: (Bool) -> Void

    @State private var selectedIndex: Int?
    @State private var strokes: [[CGPoint]] = []
    @State private var clearTrigger = 0

    private static let canvasSize = CGSize(width: 280, height: 300)

    var body: some View {
        VStack(spacing: 20) {
            prompt
                .padding(.top, 20)

            switch step.kind {
            case .draw: drawBody
            case .selectSound: selectSoundBody
            case .articulation: articulationBody
            }

            Spacer(minLength: 12)

            Button("Check") { check() }
                .buttonStyle(PillButtonStyle())
                .disabled(!canCheck)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .allowsHitTesting(!locked)
        .onAppear {
            if step.kind == .articulation {
                playTarget()
            }
        }
    }

    private var prompt: some View {
        Group {
            switch step.kind {
            case .draw:
                Text("Draw the letter along the outline, then tap Proceed")
            case .selectSound:
                Text("Select the correct sound for this letter")
            case .articulation:
                Text("Select the correct letter for this sound")
            }
        }
        .font(.system(size: AB.h3, weight: .semibold))
        .foregroundStyle(AB.darkest)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }

    private var canCheck: Bool {
        switch step.kind {
        case .draw: return !strokes.isEmpty
        case .selectSound, .articulation: return selectedIndex != nil
        }
    }

    private func check() {
        switch step.kind {
        case .draw:
            let verdict = StrokeVerifier.verify(
                strokes: strokes,
                canvasSize: Self.canvasSize,
                letterArabic: step.letter.arabic,
                strict: strict
            )
            onAnswer(verdict.passed)
        case .selectSound, .articulation:
            guard let selectedIndex, let choice = step.options[safe: selectedIndex] else { return }
            onAnswer(choice.id == step.letter.id)
        }
    }

    private func playTarget() {
        AudioService.shared.playLetter(id: step.letter.id, audioFile: step.letter.audioFile)
    }

    // MARK: - A. Draw (§4.2 A)

    private var drawBody: some View {
        VStack(spacing: 14) {
            ZStack {
                // Ghosted target letter on the 280×300 canvas.
                ArabicText(text: step.letter.arabic, size: 170, color: AB.neutral300.opacity(0.8))
                    .allowsHitTesting(false)
                StrokeInputView(strokes: $strokes, clearTrigger: clearTrigger)
            }
            .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            .background(AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
            .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)

            Text(verbatim: "\(step.letter.nameEn) · \(step.letter.transliteration)")
                .font(.system(size: AB.small))
                .foregroundStyle(AB.neutral400)

            Button {
                strokes = []
                clearTrigger += 1
            } label: {
                Label("Clear & retry", systemImage: "arrow.counterclockwise")
                    .font(.system(size: AB.small, weight: .semibold))
                    .foregroundStyle(AB.sage)
            }
            .disabled(strokes.isEmpty)
            .opacity(strokes.isEmpty ? 0.4 : 1)
        }
    }

    // MARK: - B. Select the sound (§4.2 B)

    private var selectSoundBody: some View {
        VStack(spacing: 28) {
            ArabicText(text: step.letter.arabic, size: 130, color: AB.darkest)
                .frame(width: 220, height: 220)
                .background(AB.surface)
                .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
                .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)

            HStack(spacing: 14) {
                ForEach(Array(step.options.enumerated()), id: \.element.id) { index, option in
                    SoundOptionButton(index: index, isSelected: selectedIndex == index) {
                        selectedIndex = index
                        AudioService.shared.playLetter(id: option.id, audioFile: option.audioFile)
                    }
                    .accessibilityIdentifier("sound-option-\(index)")
                }
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - C. Articulation (§4.2 C)

    private var articulationBody: some View {
        VStack(spacing: 28) {
            // Audio card: plays the target sound.
            Button {
                playTarget()
            } label: {
                VStack(spacing: 12) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 34))
                        .foregroundStyle(AB.darkest)
                        .frame(width: 76, height: 76)
                        .background(AB.saffron)
                        .clipShape(Circle())
                    Text("Tap to listen")
                        .font(.system(size: AB.small))
                        .foregroundStyle(AB.neutral400)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(AB.surface)
                .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
                .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            HStack(spacing: 14) {
                ForEach(Array(step.options.enumerated()), id: \.element.id) { index, option in
                    LetterOptionCard(arabic: option.arabic, isSelected: selectedIndex == index) {
                        selectedIndex = index
                        playTarget()   // tapping a card replays the sound (§4.2 C)
                    }
                    .accessibilityIdentifier("letter-option-\(index)")
                }
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Option controls

private struct SoundOptionButton: View {
    let index: Int
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "music.note")
                    .font(.system(size: 15, weight: .semibold))
                Text(verbatim: "\(index + 1)")
                    .font(.system(size: AB.h3, weight: .bold))
            }
            .foregroundStyle(isSelected ? AB.primary : AB.darkest)
            .frame(width: 88, height: 60)
            .background(isSelected ? AB.mintPale : AB.surface)
            .clipShape(RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous)
                    .strokeBorder(isSelected ? AB.primary : AB.neutral300, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Sound option \(index + 1)")
    }
}

private struct LetterOptionCard: View {
    let arabic: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ArabicText(text: arabic, size: 46, color: isSelected ? AB.primary : AB.darkest)
                .frame(width: 96, height: 110)
                .background(isSelected ? AB.mintPale : AB.surface)
                .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous)
                        .strokeBorder(isSelected ? AB.primary : AB.neutral300, lineWidth: isSelected ? 2 : 1)
                )
                .shadow(color: AB.cardShadow, radius: 10, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}
