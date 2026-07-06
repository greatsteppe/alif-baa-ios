//
//  LessonScreens.swift
//  alif-baa-ios
//
//  The non-exercise lesson screens (§3.1): intro, good-job praise, the two
//  vowel interstitials, harakat practice, and the summary.
//

import SwiftUI

// MARK: - Intro

struct LessonIntroView: View {
    let lesson: Lesson
    let letters: [Letter]
    let onStart: () -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AB.neutral400)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Close lesson")
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 8) {
                        Text("Lesson \(lesson.num)")
                            .font(.system(size: AB.small, weight: .medium))
                            .foregroundStyle(AB.sage)
                            .textCase(.uppercase)
                        Text(LocalizedStringKey(lesson.title))
                            .font(.system(size: AB.h2, weight: .bold))
                            .foregroundStyle(AB.darkest)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 16)

                    ArabicText(text: letters.map(\.arabic).joined(separator: "  "), size: AB.display, color: AB.primary)

                    VStack(spacing: 12) {
                        ActivityRow(icon: "pencil.tip", tint: AB.primary, title: "Draw",
                                    subtitle: "Trace each letter along its outline")
                        ActivityRow(icon: "speaker.wave.2.fill", tint: AB.saffron, title: "Pronounce",
                                    subtitle: "Match each letter with its sound")
                        ActivityRow(icon: "brain.head.profile", tint: AB.sage, title: "Memorize",
                                    subtitle: "Recognize the letter for a sound you hear")
                    }
                    .padding(.horizontal, 24)
                }
                .padding(.bottom, 24)
            }

            Button("Start") { onStart() }
                .buttonStyle(PillButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }
}

private struct ActivityRow: View {
    let icon: String
    let tint: Color
    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(tint == AB.saffron ? AB.darkest : .white)
                .frame(width: 44, height: 44)
                .background(tint)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: AB.body, weight: .semibold))
                    .foregroundStyle(AB.darkest)
                Text(subtitle)
                    .font(.system(size: AB.small))
                    .foregroundStyle(AB.neutral400)
            }
            Spacer()
        }
        .padding(16)
        .background(AB.surface)
        .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
        .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)
    }
}

// MARK: - Good job

struct GoodJobView: View {
    let onContinue: () -> Void
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "hands.clap.fill")
                .font(.system(size: 64))
                .foregroundStyle(AB.saffron)
                .scaleEffect(appeared ? 1 : 0.5)
                .animation(.spring(duration: 0.5, bounce: 0.5), value: appeared)
            Text("Good job!")
                .font(.system(size: AB.h1, weight: .bold))
                .foregroundStyle(AB.primary)
            Text("You've finished the letter exercises")
                .font(.system(size: AB.body))
                .foregroundStyle(AB.neutral400)
            Spacer()
            Text("Tap to continue")
                .font(.system(size: AB.small))
                .foregroundStyle(AB.neutral400)
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
        .onAppear { appeared = true }
    }
}

// MARK: - Vowel interstitials (§4.2 D)

struct VowelInterstitialView: View {
    enum Kind {
        case nowVowels
        case listenAndRepeat
    }

    let kind: Kind
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            switch kind {
            case .nowVowels:
                ArabicText(text: "بَ  بُ  بِ", size: AB.display, color: AB.primary)
                Text("Now Letters with Vowels")
                    .font(.system(size: AB.h2, weight: .bold))
                    .foregroundStyle(AB.darkest)
                    .multilineTextAlignment(.center)
                Text("The harakat — Fatha, Damma, Kasra — give each letter its vowel")
                    .font(.system(size: AB.body))
                    .foregroundStyle(AB.neutral400)
                    .multilineTextAlignment(.center)
            case .listenAndRepeat:
                Image(systemName: "ear")
                    .font(.system(size: 56))
                    .foregroundStyle(AB.sage)
                Text("Listen carefully and repeat")
                    .font(.system(size: AB.h2, weight: .bold))
                    .foregroundStyle(AB.darkest)
                    .multilineTextAlignment(.center)
                Text("Play each sound, then say it out loud")
                    .font(.system(size: AB.body))
                    .foregroundStyle(AB.neutral400)
                    .multilineTextAlignment(.center)
            }
            Spacer()
            Text("Tap to continue")
                .font(.system(size: AB.small))
                .foregroundStyle(AB.neutral400)
                .padding(.bottom, 32)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .onTapGesture { onContinue() }
    }
}

// MARK: - Vowels practice (§4.2 D)

struct VowelPracticeView: View {
    let letter: Letter
    let onRepeated: () -> Void

    @State private var harakat: Harakat = .fatha

    var body: some View {
        VStack(spacing: 24) {
            Text("Listen carefully and repeat")
                .font(.system(size: AB.h3, weight: .semibold))
                .foregroundStyle(AB.darkest)
                .padding(.top, 20)

            ArabicText(text: letter.arabic + harakat.mark, size: 120, color: AB.darkest)
                .frame(width: 230, height: 230)
                .background(AB.surface)
                .clipShape(RoundedRectangle(cornerRadius: AB.radiusCard, style: .continuous))
                .shadow(color: AB.cardShadow, radius: 15, x: 0, y: 4)

            Button {
                play()
            } label: {
                Image(systemName: "play.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(AB.darkest)
                    .frame(width: 64, height: 64)
                    .background(AB.saffron)
                    .clipShape(Circle())
            }
            .accessibilityLabel("Play sound")

            HStack(spacing: 12) {
                ForEach(Harakat.allCases) { candidate in
                    Button {
                        harakat = candidate
                        play()
                    } label: {
                        VStack(spacing: 4) {
                            ArabicText(
                                text: letter.arabic + candidate.mark,
                                size: AB.h2,
                                color: harakat == candidate ? AB.primary : AB.darkest
                            )
                            Text(verbatim: "\(candidate.name) · \(letter.transliteration)\(candidate.vowelSound)")
                                .font(.system(size: AB.caption))
                                .foregroundStyle(AB.neutral400)
                        }
                        .frame(width: 100, height: 92)
                        .background(harakat == candidate ? AB.mintPale : AB.surface)
                        .clipShape(RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AB.radiusSmall, style: .continuous)
                                .strokeBorder(harakat == candidate ? AB.primary : AB.neutral300,
                                              lineWidth: harakat == candidate ? 2 : 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 12)

            Button("I repeated it") { onRepeated() }
                .buttonStyle(PillButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .onAppear { play() }
    }

    private func play() {
        AudioService.shared.playLetter(id: letter.id, audioFile: letter.audioFile, harakat: harakat)
    }
}

// MARK: - Summary

struct LessonSummaryView: View {
    let lesson: Lesson
    let letters: [Letter]
    let coveredCount: Int
    let nextLesson: Lesson?
    let newItemAvailable: Bool
    let onNext: (Lesson) -> Void
    let onLibrary: () -> Void
    let onMain: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            HStack(spacing: 12) {
                ForEach(letters, id: \.id) { letter in
                    LetterChip(arabic: letter.arabic)
                }
            }

            Text("MashaAllah, you've covered \(coveredCount) letters out of 28!")
                .font(.system(size: AB.h2, weight: .bold))
                .foregroundStyle(AB.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            if newItemAvailable {
                Label("A new item is available in the Content tab", systemImage: "sparkles")
                    .font(.system(size: AB.small, weight: .medium))
                    .foregroundStyle(AB.amberDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(AB.saffron.opacity(0.15))
                    .clipShape(Capsule())
            }

            Spacer()

            VStack(spacing: 12) {
                if let nextLesson {
                    Button("Next lesson") { onNext(nextLesson) }
                        .buttonStyle(PillButtonStyle())
                }
                Button("Library") { onLibrary() }
                    .buttonStyle(PillButtonStyle(background: AB.sage))
                Button("Main") { onMain() }
                    .font(.system(size: AB.body, weight: .semibold))
                    .foregroundStyle(AB.primary)
                    .frame(height: 44)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}
