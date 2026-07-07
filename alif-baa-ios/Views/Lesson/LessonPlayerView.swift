//
//  LessonPlayerView.swift
//  alif-baa-ios
//
//  The exercise engine (§4.2): for every letter in the group it generates
//  Draw → Select-the-sound → Articulation steps, then the harakat practice,
//  closing on the summary. Works for any letter group.
//

import SwiftUI
import SwiftData

enum ExerciseKind {
    case draw
    case selectSound
    case articulation
}

struct ExerciseStep: Identifiable {
    let id = UUID()
    let kind: ExerciseKind
    let letter: Letter
    let options: [Letter]   // 3 shuffled candidates for the selection exercises
}

struct LessonPlayerView: View {

    private enum Stage {
        case intro
        case exercises
        case goodJob
        case vowelIntro1
        case vowelIntro2
        case vowels
        case summary
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Query private var settingsList: [UserSettings]
    @Query private var allLetters: [Letter]
    @Query(sort: \Lesson.num) private var allLessons: [Lesson]
    @Query private var words: [Word]

    let lesson: Lesson
    let onNextLesson: (Lesson) -> Void
    let onOpenLibrary: () -> Void

    @State private var stage: Stage = .intro
    @State private var steps: [ExerciseStep] = []
    @State private var stepIndex = 0
    @State private var vowelIndex = 0
    @State private var feedback: FeedbackKind?
    @State private var didComplete = false

    private var groupLetters: [Letter] {
        lesson.letterIds.compactMap { id in allLetters.first { $0.id == id } }
    }

    /// Strict stroke matching for non-beginners; lenient is the beginner default (§5.2).
    private var strictStrokes: Bool {
        let level = ReadingLevel(rawValue: settingsList.first?.readingLevel ?? "") ?? .beginner
        return level != .beginner
    }

    private var totalUnits: Int { steps.count + groupLetters.count }

    private var currentUnit: Int {
        switch stage {
        case .intro: return 0
        case .exercises: return stepIndex
        case .goodJob, .vowelIntro1, .vowelIntro2: return steps.count
        case .vowels: return steps.count + vowelIndex
        case .summary: return totalUnits
        }
    }

    var body: some View {
        ZStack {
            AB.cream.ignoresSafeArea()

            switch stage {
            case .intro:
                LessonIntroView(lesson: lesson, letters: groupLetters) {
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .exercises }
                } onClose: {
                    dismiss()
                }

            case .exercises:
                if let step = steps[safe: stepIndex] {
                    exerciseStage(step)
                }

            case .goodJob:
                GoodJobView {
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .vowelIntro1 }
                }

            case .vowelIntro1:
                VowelInterstitialView(kind: .nowVowels) {
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .vowelIntro2 }
                }

            case .vowelIntro2:
                VowelInterstitialView(kind: .listenAndRepeat) {
                    withAnimation(.easeInOut(duration: 0.25)) { stage = .vowels }
                }

            case .vowels:
                if let letter = groupLetters[safe: vowelIndex] {
                    vowelStage(letter)
                }

            case .summary:
                LessonSummaryView(
                    lesson: lesson,
                    letters: groupLetters,
                    coveredCount: coveredLetterCount,
                    nextLesson: allLessons.first { $0.num == lesson.num + 1 },
                    newItemAvailable: words.contains { $0.requiredLesson == lesson.num },
                    onNext: { next in onNextLesson(next) },
                    onLibrary: onOpenLibrary,
                    onMain: { dismiss() }
                )
                .onAppear(perform: completeLessonIfNeeded)
            }
        }
        .onAppear(perform: generateStepsIfNeeded)
    }

    // MARK: - Stages

    private func exerciseStage(_ step: ExerciseStep) -> some View {
        VStack(spacing: 0) {
            topBar
            ExerciseStepView(step: step, strict: strictStrokes, locked: feedback != nil) { correct in
                handleAnswer(step: step, correct: correct)
            } onRetry: {
                // Clear & retry during feedback: dismiss the banner and stay
                // on this step for another attempt.
                feedback = nil
            }
            .id(step.id)
        }
        .overlay(alignment: .bottom) {
            if let feedback {
                FeedbackBanner(kind: feedback) { advanceAfterFeedback() }
            }
        }
        .animation(.spring(duration: 0.35), value: feedback)
    }

    private func vowelStage(_ letter: Letter) -> some View {
        VStack(spacing: 0) {
            topBar
            VowelPracticeView(letter: letter) {
                for harakat in Harakat.allCases {
                    SRSService.record(
                        context: context,
                        itemType: "vowelledLetter",
                        itemId: "\(letter.id)-\(harakat.rawValue)",
                        quality: 4
                    )
                }
                withAnimation(.easeInOut(duration: 0.25)) {
                    if vowelIndex + 1 < groupLetters.count {
                        vowelIndex += 1
                    } else {
                        stage = .summary
                    }
                }
            }
            .id(letter.id)
        }
    }

    /// Close (X) + saffron progress bar + step counter (§4.2).
    private var topBar: some View {
        HStack(spacing: 14) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(AB.neutral400)
                    .frame(width: 44, height: 44)
            }
            .accessibilityLabel("Close lesson")

            SaffronProgressBar(progress: totalUnits > 0 ? Double(currentUnit) / Double(totalUnits) : 0)

            Text(verbatim: "\(min(currentUnit + 1, totalUnits))/\(totalUnits)")
                .font(.system(size: AB.small, weight: .medium).monospacedDigit())
                .foregroundStyle(AB.neutral400)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Engine

    private func generateStepsIfNeeded() {
        guard steps.isEmpty else { return }
        steps = groupLetters.flatMap { letter in
            [
                ExerciseStep(kind: .draw, letter: letter, options: []),
                ExerciseStep(kind: .selectSound, letter: letter, options: options(for: letter)),
                ExerciseStep(kind: .articulation, letter: letter, options: options(for: letter)),
            ]
        }
    }

    /// Three candidates: the target plus two distractors, preferring the lesson's own group.
    private func options(for letter: Letter) -> [Letter] {
        var pool = groupLetters.filter { $0.id != letter.id }.shuffled()
        if pool.count < 2 {
            let extras = allLetters
                .filter { candidate in candidate.id != letter.id && !pool.contains { $0.id == candidate.id } }
                .shuffled()
            pool.append(contentsOf: extras)
        }
        return ([letter] + pool.prefix(2)).shuffled()
    }

    private func handleAnswer(step: ExerciseStep, correct: Bool) {
        if correct {
            AudioService.shared.playCorrect()
            feedback = .correct(praise: FeedbackBanner.randomPraise())
        } else {
            AudioService.shared.playWrong()
            let answer = step.kind == .draw ? nil : "\(step.letter.nameEn) — \(step.letter.arabic)"
            feedback = .wrong(correctAnswer: answer)
        }
        SRSService.record(
            context: context,
            itemType: "letter",
            itemId: "\(step.letter.id)",
            quality: correct ? 5 : 2
        )
    }

    private func advanceAfterFeedback() {
        feedback = nil
        withAnimation(.easeInOut(duration: 0.25)) {
            if stepIndex + 1 < steps.count {
                stepIndex += 1
            } else {
                stage = .goodJob
            }
        }
    }

    // MARK: - Completion

    /// Distinct letters across all completed lessons, this one included (§3.1 summary).
    private var coveredLetterCount: Int {
        let completed = allLessons.filter { $0.isComplete || $0.num == lesson.num }
        return Set(completed.flatMap(\.letterIds)).count
    }

    private func completeLessonIfNeeded() {
        guard !didComplete else { return }
        didComplete = true
        lesson.isComplete = true
        if let next = allLessons.first(where: { $0.num == lesson.num + 1 }) {
            next.isUnlocked = true
        }
        try? context.save()
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
